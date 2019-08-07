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
static const std::string s_rsStart = "rs.";
static const std::string s_byte = "b";
static const std::string s_word = "w";
static const std::string s_long = "l";

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

			//Parse components
			for (int i = 0; i < m_componentTextBlocks.size(); i++)
			{
				Component component;
				if (ParseComponent(m_componentTextBlocks[i], component))
				{
					m_components.push_back(component);
				}
			}

			//Parse entities
			for (int i = 0; i < m_entitySpawnTextBlocks.size(); i++)
			{
				Entity entity;
				if (ParseEntity(m_entitySpawnTextBlocks[i], entity))
				{
					entities.push_back(entity);
				}
			}

			return true;
		}

		return false;
	}

	std::string EntityParser::FindEntityName(const std::string& line, size_t pos)
	{
		//Trim starting whitespace
		std::string name = line.substr(pos + s_entityBegin.size(), line.size() - (pos + s_entityBegin.size()));
		name = ion::string::TrimWhitespaceStart(name);

		//Trim up to comment, if there is one
		size_t commentPos = name.find_first_of(';');
		if(commentPos != std::string::npos)
			name = line.substr(name.find_first_of(';'), name.size() - commentPos);

		//Trim ending whitespace
		name = ion::string::TrimWhitespaceEnd(name);

		return name;
	}

	std::string EntityParser::FindComponentName(std::string line, size_t pos)
	{
		//Trim starting whitespace
		std::string name = line.substr(pos + s_componentBegin.size(), line.size() - (pos + s_componentBegin.size()));
		name = ion::string::TrimWhitespaceStart(name);

		//Trim up to comment, if there is one
		size_t commentPos = name.find_first_of(';');
		if (commentPos != std::string::npos)
			name = line.substr(name.find_first_of(';'), name.size() - commentPos);

		//Trim ending whitespace
		name = ion::string::TrimWhitespaceEnd(name);

		return name;
	}

	std::string EntityParser::FindEntitySpawnName(const std::string& line, size_t pos)
	{
		//Trim starting whitespace
		std::string name = line.substr(pos + s_entitySpawnBegin.size(), line.size() - (pos + s_entitySpawnBegin.size()));
		name = ion::string::TrimWhitespaceStart(name);

		//Trim up to comment, if there is one
		size_t commentPos = name.find_first_of(';');
		if (commentPos != std::string::npos)
			name = line.substr(name.find_first_of(';'), name.size() - commentPos);

		//Trim ending whitespace
		name = ion::string::TrimWhitespaceEnd(name);

		return name;
	}

	std::string EntityParser::FindComponentSpawnName(std::string line, size_t pos)
	{
		//Trim starting whitespace
		std::string name = line.substr(pos + s_componentSpawnBegin.size(), line.size() - (pos + s_componentSpawnBegin.size()));
		name = ion::string::TrimWhitespaceStart(name);

		//Trim up to comment, if there is one
		size_t commentPos = name.find_first_of(';');
		if (commentPos != std::string::npos)
			name = line.substr(name.find_first_of(';'), name.size() - commentPos);

		//Trim ending whitespace
		name = ion::string::TrimWhitespaceEnd(name);

		return name;
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
			bool inMacroBlock = false;

			TextBlock currentBlock;

			for (int i = 0; i < lines.size(); i++)
			{
				//Ignore comment lines
				std::string strippedStart = ion::string::TrimWhitespaceStart(lines[i]);

				if (!ion::string::StartsWith(strippedStart, s_comment))
				{
					if (inMacroBlock)
					{
						//Ignore macro definition until it finishes
						if (ion::string::ToLower(strippedStart).find(s_macroEnd) != std::string::npos)
						{
							inMacroBlock = false;
						}
					}
					else
					{
						if (ion::string::ToLower(strippedStart).find(s_macroStart) != std::string::npos)
						{
							//Found  macro block, ignoring everything in here
							inMacroBlock = true;
						}
						else
						{
							if (inEntitySpawnBlock)
							{
								//In entity spawn data block, collect lines until we find the end
								if (strippedStart.find(s_entitySpawnEnd) != std::string::npos)
								{
									inEntitySpawnBlock = false;
									m_entitySpawnTextBlocks.push_back(currentBlock);
									currentBlock = TextBlock();
								}
								else
								{
									currentBlock.block.push_back(strippedStart);
								}
							}
							else if (inComponentSpawnBlock)
							{
								//In component spawn block, collect lines until we find the end
								if (strippedStart.find(s_componentSpawnEnd) != std::string::npos)
								{
									inComponentSpawnBlock = false;
									m_componentSpawnTextBlocks.push_back(currentBlock);
									currentBlock = TextBlock();
								}
								else
								{
									currentBlock.block.push_back(strippedStart);
								}
							}
							else
							{
								//Find an entity, component, or spawn data blocks
								size_t pos = std::string::npos;

								if ((pos = strippedStart.find(s_entitySpawnBegin)) != std::string::npos)
								{
									currentBlock.name = FindEntitySpawnName(strippedStart, pos);
									inEntitySpawnBlock = true;
								}
								else if ((pos = strippedStart.find(s_componentSpawnBegin)) != std::string::npos)
								{
									currentBlock.name = FindComponentSpawnName(strippedStart, pos);
									inComponentSpawnBlock = true;
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

			if ((componentPos = textBlock.block[i].find(s_componentDef)) != std::string::npos)
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

		return entity.name.size() > 0;
	}

	bool EntityParser::ParseComponent(const TextBlock& textBlock, Component& component)
	{
		for (int i = 0; i < textBlock.block.size(); i++)
		{
			Param param;
			if (ParseParam(textBlock.block[i], param))
			{
				component.params.push_back(param);
			}
		}

		return component.name.size() > 0;
	}

	bool EntityParser::ParseParam(const std::string& line, Param& param)
	{
		//Extract name
		std::string strippedStart = ion::string::TrimWhitespaceStart(line);
		size_t nameEnd = ion::string::FindFirstWhitespace(line);
		param.name = strippedStart.substr(0, nameEnd);

		//Isolate RS
		std::string rs = strippedStart.substr(nameEnd, strippedStart.size() - nameEnd);
		rs = ion::string::TrimWhitespaceStart(rs);
		size_t rsStart = rs.find(s_rsStart);

		if (rsStart != std::string::npos)
		{
			rs = rs.substr(rsStart + s_rsStart.size(), rs.size() - (rsStart + s_rsStart.size()));
			rs = ion::string::ToLower(rs);

			if (ion::string::StartsWith(rs, s_byte))
			{
				param.size = ParamSize::Byte;
			}
			else if (ion::string::StartsWith(rs, s_word))
			{
				param.size = ParamSize::Word;
			}
			else if (ion::string::StartsWith(rs, s_long))
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

	Component* EntityParser::ParseComponentDef(const std::string& line, size_t pos)
	{
		//Trim starting whitespace
		std::string name = line.substr(pos + s_componentDef.size(), line.size() - (pos + s_componentDef.size()));
		name = ion::string::TrimWhitespaceStart(name);

		//Trim up to comment, if there is one
		size_t commentPos = name.find_first_of(';');
		if (commentPos != std::string::npos)
			name = line.substr(name.find_first_of(';'), name.size() - commentPos);

		//Trim ending whitespace
		name = ion::string::TrimWhitespaceEnd(name);

		//Find component
		Component* component = nullptr;

		for (int i = 0; i < m_components.size() && !component; i++)
		{
			if (ion::string::CompareNoCase(m_components[i].name, name))
			{
				component = &m_components[i];
			}
		}

		return component;
	}
}
