// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 6th August 2019
// ============================================================================================
// EntityParser.cpp - Utilities for parsing the Luminary engine and game files to build lists
// of entities and components for tools exporting.
// ============================================================================================

#include "EntityParser.h"

#include <ion/io/File.h>
#include <ion/io/FileDevice.h>
#include <ion/core/string/String.h>

#include <cctype>

static const std::vector<std::string> s_asmExtensions =
{
	".asm",
	".s"
};

static const std::string s_entityBegin = "ENTITY_BEGIN";
static const std::string s_entityEnd = "ENTITY_END";
static const std::string s_staticEntityBegin = "STATIC_ENTITY_BEGIN";
static const std::string s_staticEntityEnd = "STATIC_ENTITY_END";
static const std::string s_entitySpawnBegin = "ENTITY_SPAWN_DATA_BEGIN";
static const std::string s_entitySpawnEnd = "ENTITY_SPAWN_DATA_END";
static const std::string s_componentBegin = "ENTITY_COMPONENT_BEGIN";
static const std::string s_componentEnd = "ENTITY_COMPONENT_END";
static const std::string s_componentSpawnBegin = "COMPONENT_SPAWN_DATA_BEGIN";
static const std::string s_componentSpawnEnd = "COMPONENT_SPAWN_DATA_END";
static const std::string s_componentDef = "ENT_COMPONENT";
static const std::string s_componentNamedDef = "ENT_COMPONENT_NAMED";
static const std::string s_scriptFuncDef = "SCRIPT_FUNC";
static const std::string s_macroStart = "macro";
static const std::string s_macroEnd = "endm";
static const std::string s_comment = ";";
static const std::string s_rsByte = "rs.b";
static const std::string s_rsWord = "rs.w";
static const std::string s_rsLong = "rs.l";
static const std::string s_tagStart = "[TAGS=";
static const std::string s_tagEnd = "]";
static const std::string s_tagDelim = ",";
static const std::vector<char> s_tokenDelim = { ' ', ',', '\t' };
static const std::vector<char> s_lineEndings = { '\r', '\n' };

namespace luminary
{
	EntityParser::EntityParser()
	{

	}

	void RecursiveFindASMFiles(ion::io::FileDevice& fileDevice, const std::string& directory, std::vector<std::string>& asmFiles)
	{
		std::vector<ion::io::FileDevice::DirectoryItem> contents;
		fileDevice.ReadDirectory(directory, contents);

		for (int i = 0; i < contents.size(); i++)
		{
			if (contents[i].m_fileType == ion::io::FileDevice::eDirectory)
			{
				if (contents[i].m_filename != "." && contents[i].m_filename != "..")
				{
					std::string subDir = directory + fileDevice.GetPathSeparator() + contents[i].m_filename;
					RecursiveFindASMFiles(fileDevice, subDir, asmFiles);
				}
			}
			else if (contents[i].m_fileType == ion::io::FileDevice::eFile)
			{
				for (int j = 0; j < s_asmExtensions.size(); j++)
				{
					if (ion::string::EndsWith(ion::string::ToLower(contents[i].m_filename), s_asmExtensions[j]))
					{
						std::string fullPath = directory + fileDevice.GetPathSeparator() + contents[i].m_filename;

						if (std::find(asmFiles.begin(), asmFiles.end(), fullPath) == asmFiles.end())
						{
							asmFiles.push_back(fullPath);
						}

						break;
					}
				}
			}
		}
	}

	bool EntityParser::ParseDirectories(const std::vector<std::string>& directories, std::vector<Entity>& entities)
	{
		if (ion::io::FileDevice::GetDefault())
		{
			for (auto directory : directories)
			{
				//Recursively search directory for ASM files
				std::vector<std::string> asmFiles;
				RecursiveFindASMFiles(*ion::io::FileDevice::GetDefault(), directory, asmFiles);

				//Find all entity and component text blocks
				for (int i = 0; i < asmFiles.size(); i++)
				{
					FindTextBlocks(asmFiles[i]);
				}

				//Parse component spawn data
				for (int i = 0; i < m_componentSpawnTextBlocks.size(); i++)
				{
					SpawnData spawnData;
					ParseSpawnData(m_componentSpawnTextBlocks[i], spawnData);
					m_componentSpawnData.push_back(spawnData);
				}

				//Parse entity spawn data
				for (int i = 0; i < m_entitySpawnTextBlocks.size(); i++)
				{
					SpawnData spawnData;
					ParseSpawnData(m_entitySpawnTextBlocks[i], spawnData);
					m_entitySpawnData.push_back(spawnData);
				}

				//Parse components and match with spawn data
				for (int i = 0; i < m_componentTextBlocks.size(); i++)
				{
					Component component;
					if (ParseComponent(m_componentTextBlocks[i], component))
					{
						m_components.push_back(component);
					}
				}

				//Parse entities and match with spawn data
				for (int i = 0; i < m_entityTextBlocks.size(); i++)
				{
					Entity entity;
					if (ParseEntity(m_entityTextBlocks[i], entity))
					{
						entities.push_back(entity);
					}
				}

				//Parse static entities
				for (int i = 0; i < m_staticEntityTextBlocks.size(); i++)
				{
					Entity entity;
					ParseStaticEntity(m_staticEntityTextBlocks[i], entity);
					entities.push_back(entity);
				}
			}

			return true;
		}

		return false;
	}

	std::string EntityParser::GetNameToken(const std::vector<std::string>& tokens)
	{
		//A name should always follow the entity/component/spawn macro
		if (tokens.size() >= 2)
		{
			return tokens[1];
		}

		return "";
	}

	int ContainsToken(const std::vector<std::string>& tokens, const std::string& string)
	{
		for (int i = 0; i < tokens.size(); i++)
		{
			if (ion::string::CompareNoCase(tokens[i], string))
			{
				return i;
			}
		}

		return -1;
	}

	int TokenStartsWith(const std::vector<std::string>& tokens, const std::string& string)
	{
		std::string lower = ion::string::ToLower(string);

		for (int i = 0; i < tokens.size(); i++)
		{
			if (ion::string::StartsWith(ion::string::ToLower(tokens[i]), lower))
			{
				return i;
			}
		}

		return -1;
	}

	void EntityParser::FindTextBlocks(const std::string& filename)
	{
		ion::io::File file(filename, ion::io::File::eOpenRead);
		if (file.IsOpen())
		{
			//Read file contents
			std::string contents;
			contents.resize(file.GetSize());
			file.Read(&contents[0], file.GetSize());

			//Extract lines
			std::vector<std::string> lines;
			ion::string::Tokenise(contents, lines, s_lineEndings);

			bool inEntitySpawnBlock = false;
			bool inComponentSpawnBlock = false;
			bool inEntityBlock = false;
			bool inStaticEntityBlock = false;
			bool inComponentBlock = false;
			bool inMacroBlock = false;

			TextBlock currentBlock;

			for (int i = 0; i < lines.size(); i++)
			{
				//Tokenise
				std::vector<std::string> words;
				ion::string::Tokenise(lines[i], words, s_tokenDelim);

				if (words.size() > 0)
				{
					//Ignore comment lines
					if (words[0][0] != ';')
					{
						if (inMacroBlock)
						{
							//Ignore macro definition until it finishes
							if (ContainsToken(words, s_macroEnd) >= 0)
							{
								inMacroBlock = false;
							}
						}
						else
						{
							if (ContainsToken(words, s_macroStart) >= 0)
							{
								//Found  macro block, ignoring everything in here
								inMacroBlock = true;
							}
							else
							{
								if (inEntitySpawnBlock)
								{
									//In entity spawn data block, collect lines until we find the end
									if (ContainsToken(words, s_entitySpawnEnd) >= 0)
									{
										inEntitySpawnBlock = false;
										m_entitySpawnTextBlocks.push_back(currentBlock);
										currentBlock = TextBlock();
									}
									else
									{
										currentBlock.block.push_back(words);
									}
								}
								else if (inComponentSpawnBlock)
								{
									//In component spawn block, collect lines until we find the end
									if (ContainsToken(words, s_componentSpawnEnd) >= 0)
									{
										inComponentSpawnBlock = false;
										m_componentSpawnTextBlocks.push_back(currentBlock);
										currentBlock = TextBlock();
									}
									else
									{
										currentBlock.block.push_back(words);
									}
								}
								else if (inEntityBlock)
								{
									//In entity block, collect lines until we find the end
									if (ContainsToken(words, s_entityEnd) >= 0)
									{
										inEntityBlock = false;
										m_entityTextBlocks.push_back(currentBlock);
										currentBlock = TextBlock();
									}
									else
									{
										currentBlock.block.push_back(words);
									}
								}
								else if (inStaticEntityBlock)
								{
									//In static entity block, collect lines until we find the end
									if (ContainsToken(words, s_staticEntityEnd) >= 0)
									{
										inStaticEntityBlock = false;
										m_staticEntityTextBlocks.push_back(currentBlock);
										currentBlock = TextBlock();
									}
									else
									{
										currentBlock.block.push_back(words);
									}
								}
								else if (inComponentBlock)
								{
									//In component block, collect lines until we find the end
									if (ContainsToken(words, s_componentEnd) >= 0)
									{
										inComponentBlock = false;
										m_componentTextBlocks.push_back(currentBlock);
										currentBlock = TextBlock();
									}
									else
									{
										currentBlock.block.push_back(words);
									}
								}
								else
								{
									//Find an entity, component, or spawn data blocks
									int pos = -1;

									if ((pos = ContainsToken(words, s_entitySpawnBegin)) >= 0)
									{
										currentBlock.name = GetNameToken(words);
										inEntitySpawnBlock = true;
									}
									else if ((pos = ContainsToken(words, s_componentSpawnBegin)) >= 0)
									{
										currentBlock.name = GetNameToken(words);
										inComponentSpawnBlock = true;
									}
									else if ((pos = ContainsToken(words, s_entityBegin)) >= 0)
									{
										currentBlock.name = GetNameToken(words);
										inEntityBlock = true;
									}
									else if ((pos = ContainsToken(words, s_staticEntityBegin)) >= 0)
									{
										currentBlock.name = GetNameToken(words);
										inStaticEntityBlock = true;
									}
									else if ((pos = ContainsToken(words, s_componentBegin)) >= 0)
									{
										currentBlock.name = GetNameToken(words);
										inComponentBlock = true;
									}
								}
							}
						}
					}
				}
			}

			file.Close();
		}
	}

	void EntityParser::ParseSpawnData(const TextBlock& textBlock, SpawnData& spawnData)
	{
		spawnData.name = textBlock.name;

		for (int i = 0; i < textBlock.block.size(); i++)
		{
			Param param;
			if (ParseParam(textBlock.block[i], param))
			{
				spawnData.params.push_back(param);
			}
		}
	}

	bool EntityParser::ParseEntity(const TextBlock& textBlock, Entity& entity)
	{
		entity.name = textBlock.name;
		entity.isStatic = false;

		//Find components and script functions, and parse params
		for (int i = 0; i < textBlock.block.size(); i++)
		{
			int tokenPos = -1;

			if ((tokenPos = ContainsToken(textBlock.block[i], s_componentNamedDef)) >= 0)
			{
				if (Component* component = ParseComponentDef(textBlock.block[i], tokenPos))
				{
					entity.components.push_back(*component);
				}
			}
			else if ((tokenPos = ContainsToken(textBlock.block[i], s_componentDef)) >= 0)
			{
				if (Component* component = ParseComponentDef(textBlock.block[i], tokenPos))
				{
					entity.components.push_back(*component);
				}
			}
			else if ((tokenPos = ContainsToken(textBlock.block[i], s_scriptFuncDef)) >= 0)
			{
				ScriptFunc scriptFunc = ParseScriptFuncDef(textBlock.block[i], tokenPos);
				scriptFunc.scope = entity.name;
				entity.scriptFuncs.push_back(scriptFunc);
			}
			else
			{
				Param param;
				if (ParseParam(textBlock.block[i], param))
				{
					entity.params.push_back(param);
				}
			}
		}

		//Match with spawn data
		if (SpawnData* spawnData = FindEntitySpawnData(entity.name))
		{
			entity.spawnData = *spawnData;
		}

		return entity.name.size() > 0;
	}

	void EntityParser::ParseStaticEntity(const TextBlock& textBlock, Entity& entity)
	{
		entity.name = textBlock.name;
		entity.isStatic = true;

		for (int i = 0; i < textBlock.block.size(); i++)
		{
			Param param;
			if (ParseParam(textBlock.block[i], param))
			{
				entity.params.push_back(param);
			}
		}
	}

	bool EntityParser::ParseComponent(const TextBlock& textBlock, Component& component)
	{
		component.name = textBlock.name;

		//Parse params
		for (int i = 0; i < textBlock.block.size(); i++)
		{
			int tokenPos = 0;

			if ((tokenPos = ContainsToken(textBlock.block[i], s_scriptFuncDef)) >= 0)
			{
				ScriptFunc scriptFunc = ParseScriptFuncDef(textBlock.block[i], tokenPos);
				scriptFunc.scope = component.name;
				component.scriptFuncs.push_back(scriptFunc);
			}
			else
			{
				Param param;
				if (ParseParam(textBlock.block[i], param))
				{
					component.params.push_back(param);
				}
			}
		}

		//Match with spawn data
		if (SpawnData* spawnData = FindComponentSpawnData(component.name))
		{
			component.spawnData = *spawnData;
		}

		return component.name.size() > 0;
	}

	bool EntityParser::ParseParam(const std::vector<std::string>& line, Param& param)
	{
		//Expecting at least 2 tokens - name and RS size
		if (line.size() >= 2)
		{
			//Name first
			param.name = line[0];

			//RS second
			if (ion::string::CompareNoCase(line[1], s_rsByte))
			{
				param.size = ParamSize::Byte;
			}
			else if (ion::string::CompareNoCase(line[1], s_rsWord))
			{
				param.size = ParamSize::Word;
			}
			else if (ion::string::CompareNoCase(line[1], s_rsLong))
			{
				param.size = ParamSize::Long;
			}
			else
			{
				return false;
			}

			//Check for tags
			int tags = -1;
			if ((tags = TokenStartsWith(line, s_tagStart)) >= 0)
			{
				ParseTags(line[tags], param);
			}

			return true;
		}
		
		return false;
	}

	void EntityParser::ParseTags(const std::string& tagLine, Param& param)
	{
		if (ion::string::StartsWith(tagLine, s_tagStart))
		{
			//Extract tag keywords
			std::string tags = tagLine.substr(s_tagStart.size(), tagLine.size() - s_tagStart.size());
			size_t tagEnd = tags.find_first_of(s_tagEnd);
			tags = tags.substr(0, tagEnd);

			//Tokenise all tags
			ion::string::Tokenise(tags, param.tags, s_tagDelim);
		}
	}

	Component* EntityParser::ParseComponentDef(const std::vector<std::string>& line, int pos)
	{
		Component* component = nullptr;

		//Expecting at least 2 tokens - macro and component name
		if (line.size() >= 2)
		{
			//Find component
			std::string componentName = line[1];

			for (int i = 0; i < m_components.size() && !component; i++)
			{
				if (ion::string::CompareNoCase(m_components[i].name, componentName))
				{
					component = &m_components[i];
				}
			}
		}

		return component;
	}

	ScriptFunc EntityParser::ParseScriptFuncDef(const std::vector<std::string>& line, int pos)
	{
		ScriptFunc scriptFunc;

		//Expecting at least 4 tokens - macro, routine, return value, name, and optional params
		if (line.size() >= 3)
		{
			scriptFunc.routine = line[1];
			scriptFunc.returnType = line[2];
			scriptFunc.name = line[3];

			if (line.size() >= 5)
			{
				//Read all func params
				for (int i = 4; i < line.size(); i += 2)
				{
					scriptFunc.params.push_back(std::make_pair(line[i], line[i + 1]));
				}
			}
		}

		return scriptFunc;
	}

	SpawnData* EntityParser::FindComponentSpawnData(const std::string& componentName)
	{
		SpawnData* spawnData = nullptr;

		for (int i = 0; i < m_componentSpawnData.size() && !spawnData; i++)
		{
			if (ion::string::CompareNoCase(m_componentSpawnData[i].name, componentName))
			{
				spawnData = &m_componentSpawnData[i];
			}
		}

		return spawnData;
	}

	SpawnData* EntityParser::FindEntitySpawnData(const std::string& entityName)
	{
		SpawnData* spawnData = nullptr;

		for (int i = 0; i < m_entitySpawnData.size() && !spawnData; i++)
		{
			if (ion::string::CompareNoCase(m_entitySpawnData[i].name, entityName))
			{
				spawnData = &m_entitySpawnData[i];
			}
		}

		return spawnData;
	}
}
