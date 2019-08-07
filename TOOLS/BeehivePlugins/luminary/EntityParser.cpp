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
#include <ion/core/string/String.h>

#include <cctype>

static const std::vector<std::string> s_asmExtensions =
{
	".asm",
	".s"
};

static const std::string s_entityBegin = "ENTITY_BEGIN";
static const std::string s_entityEnd = "ENTITY_END";
static const std::string s_entitySpawnBegin = "ENTITY_SPAWN_DATA_BEGIN";
static const std::string s_entitySpawnEnd = "ENTITY_SPAWN_DATA_END";
static const std::string s_componentBegin = "ENTITY_COMPONENT_BEGIN";
static const std::string s_componentEnd = "ENTITY_COMPONENT_END";
static const std::string s_componentSpawnBegin = "COMPONENT_SPAWN_DATA_BEGIN";
static const std::string s_componentSpawnEnd = "COMPONENT_SPAWN_DATA_END";
static const std::string s_componentDef = "ENT_COMPONENT";
static const std::string s_macroStart = "macro";
static const std::string s_macroEnd = "endm";
static const std::string s_comment = ";";
static const std::string s_rsByte = "rs.b";
static const std::string s_rsWord = "rs.w";
static const std::string s_rsLong = "rs.l";

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
						asmFiles.push_back(fullPath);
						break;
					}
				}
			}
		}
	}

	bool EntityParser::ParseDirectory(const std::string& directory, std::vector<Entity>& entities)
	{
		if (m_fileSystem.GetDefaultFileDevice())
		{
			//Recursively search directory for ASM files
			std::vector<std::string> asmFiles;
			RecursiveFindASMFiles(*m_fileSystem.GetDefaultFileDevice(), directory, asmFiles);

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
			ion::string::Tokenise(contents, lines, '\r');

			bool inEntitySpawnBlock = false;
			bool inComponentSpawnBlock = false;
			bool inEntityBlock = false;
			bool inComponentBlock = false;
			bool inMacroBlock = false;

			TextBlock currentBlock;

			for (int i = 0; i < lines.size(); i++)
			{
				//Tokenise
				std::vector<std::string> words;
				ion::string::TokeniseByWhitespace(lines[i], words);

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
									//In entity spawn data block, collect lines until we find the end
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
								else if (inComponentBlock)
								{
									//In component spawn block, collect lines until we find the end
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

		//Find components, and parse params
		for (int i = 0; i < textBlock.block.size(); i++)
		{
			size_t componentPos = std::string::npos;

			if ((componentPos = ContainsToken(textBlock.block[i], s_componentDef)) >= 0)
			{
				if (Component* component = ParseComponentDef(textBlock.block[i], componentPos))
				{
					entity.components.push_back(*component);
				}
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

	bool EntityParser::ParseComponent(const TextBlock& textBlock, Component& component)
	{
		component.name = textBlock.name;

		//Parse params
		for (int i = 0; i < textBlock.block.size(); i++)
		{
			Param param;
			if (ParseParam(textBlock.block[i], param))
			{
				component.params.push_back(param);
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

			return true;
		}
		
		return false;
	}

	Component* EntityParser::ParseComponentDef(const std::vector<std::string>& line, size_t pos)
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
