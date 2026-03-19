// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 16th March 2026
// ============================================================================================
// Serialiser.h - ASM-compatible text and binary writers
// ============================================================================================

#pragma once

#include <ion/core/io/File.h>
#include <ion/core/utils/STL.h>
#include <ion/core/string/String.h>
#include <ion/core/debug/Debug.h>
#include <ion/maths/Vector.h>

#include <sstream>

namespace luminary
{
	class SerialiserAsm
	{
	public:
		SerialiserAsm(const std::string& filename)
			: m_file(filename, ion::io::File::OpenMode::Write)
		{

		}

		~SerialiserAsm()
		{
			if (IsOpen())
			{
				m_file.Write(m_stream.str().c_str(), m_stream.str().size());
				m_file.Close();
			}
		}

		bool IsOpen() const { return m_file.IsOpen(); }

		void Comment(const std::string& comment)
		{
			m_stream << "\t; " << comment << std::endl;
		}

		void IfDef(const std::string& condition)
		{
			m_stream << "\tIFD " << condition << std::endl;
		}

		void IfNDef(const std::string& condition)
		{
			m_stream << "\tIFND " << condition << std::endl;
		}

		void EndIf()
		{
			m_stream << "\tENDIF" << std::endl;
		}

		void Label(std::string label)
		{
			m_stream << label << ":" << std::endl;
		}

		template <typename... T> void Label(std::string label, T...rest)
		{
			m_stream << label;
			Recurse(rest...);
			m_stream << ":" << std::endl;
		}

		template <typename T> void Define(const std::string& name, T value)
		{
			m_stream << name << "\t\tequ ";

			switch (sizeof(T))
			{
			case 1:
				m_stream << "0x" << SSTREAM_HEX2(value);
				break;
			case 2:
				m_stream << "0x" << SSTREAM_HEX4(value);
				break;
			case 4:
				m_stream << "0x" << SSTREAM_HEX8(value);
				break;
			default:
				ion::debug::Error("luminary::SerialiserAsm::Define() - unsupported type size");
				break;
			}

			m_stream << std::endl;
		}

		void Define(const std::string& name, const std::string& value)
		{
			m_stream << name << "\t\tequ " << value << std::endl;
		}

		void Value(u8 value, const std::string& comment = "")
		{
			m_stream << "\tdc.b " << "0x" << SSTREAM_HEX2(value);
			if(!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Value(u16 value, const std::string& comment = "")
		{
			m_stream << "\tdc.w " << "0x" << SSTREAM_HEX4(value);
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Value(int value, const std::string& comment = "")
		{
			m_stream << "\tdc.l " << "0x" << SSTREAM_HEX8(value);
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Value(u32 value, const std::string& comment = "")
		{
			m_stream << "\tdc.l " << "0x" << SSTREAM_HEX8(value);
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Value(std::string value)
		{
			if(value.empty())
				m_stream << "\tdc.l 0x00000000" << std::endl;
			else
				m_stream << "\tdc.l " << value << std::endl;
		}

		template <typename... T> void Value(std::string value, T...rest)
		{
			m_stream << "\tdc.l " << value;
			Recurse(rest...);
			m_stream << std::endl;
		}

		void Value(const ion::Vector2i& value, const std::string& comment = "")
		{
			m_stream << "\tdc.w " << "0x" << SSTREAM_HEX4(value.x) << ", " << "0x" << SSTREAM_HEX4(value.y);
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Value(s32 x, s32 y, const std::string& comment = "")
		{
			m_stream << "\tdc.w " << "0x" << SSTREAM_HEX8(x) << ", " << "0x" << SSTREAM_HEX8(y);
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Byte(const std::string& value, const std::string& comment = "")
		{
			m_stream << "\tdc.b " << value;
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Word(const std::string& value, const std::string& comment = "")
		{
			m_stream << "\tdc.w " << value;
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void Long(const std::string& value, const std::string& comment = "")
		{
			m_stream << "\tdc.l " << value;
			if (!comment.empty())
				m_stream << "\t; " << comment;
			m_stream << std::endl;
		}

		void FixedString(const std::string& str, int maxLength)
		{
			if (str.size() > maxLength - 1)
			{
				m_stream << ("\tdc.b \"" + str.substr(0, maxLength - 1) + "\",0") << std::endl;
			}
			else
			{
				std::string out = "\tdc.b \"" + str.substr(0, maxLength - 1) + "\"";

				for (int i = 0; i < maxLength - str.size(); i++)
				{
					out += ",0";
				}

				m_stream << out << std::endl;
			}
		}

		void Break()
		{
			m_stream << std::endl;
		}

		void Align()
		{
			m_stream << "\teven" << std::endl;
		}
		
	private:
		void Recurse(std::string str)
		{
			m_stream << str;
		}

		template <typename... T> void Recurse(std::string str, T...rest)
		{
			m_stream << str;
			Recurse(rest...);
		}

		ion::io::File m_file;
		std::stringstream m_stream;
	};
}