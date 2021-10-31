using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;

namespace YarnToLuminary
{
    static class Sanitise
    {
        public static string GenerateLabel(string name, string input)
        {
            // If it's prefixed with a path, remove
            input = Path.GetFileName(input);
            return "Yarn_" + name + "_" + Regex.Replace(input, "[^a-zA-Z0-9]", "");
        }

        public static string SanitiseText(string input)
        {
            return Regex.Replace(input, "[^a-zA-Z0-9?!()/:', ]", "");
        }
    }
}
