using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;

namespace YarnToLuminary
{
    class Program
    {
        static void ShowHelp()
        {
            Console.WriteLine("= Yarn To Luminary Compiler and Converter =");
            Console.WriteLine("Matt Phillips, Big Evil Corporation 2021");
            Console.WriteLine("");
            Console.WriteLine("Usage:");
            Console.WriteLine(" yarn2luminary.exe input.yarn output.asm name");
            Console.WriteLine("");
            Console.WriteLine("YarnSpinner compiler from: github.com/YarnSpinnerTool");
        }

        static int Main(string[] args)
        {
            if(args.Length != 3)
            {
                ShowHelp();
                return -1;
            }
            
            Yarn.Compiler.CompilationJob compilationJob = Yarn.Compiler.CompilationJob.CreateFromFiles(new string[] { args[0] });
            Yarn.Compiler.CompilationResult result = Yarn.Compiler.Compiler.Compile(compilationJob);

            if (result.Program == null)
            {
                Console.WriteLine("Compile error, quitting");
                return -1;
            }

            // Create output directory
            Directory.CreateDirectory(Path.GetDirectoryName(args[1]));

            using (System.IO.StreamWriter writer = new System.IO.StreamWriter(args[1]))
            {
                string header = "Generated with YarnToLuminary.exe on " + DateTime.Today.Date.ToShortDateString() + " from " + args[0] + " ";
                writer.WriteLine("; " + string.Concat(Enumerable.Repeat("=", header.Length)));
                writer.WriteLine("; " + header);
                writer.WriteLine("; " + string.Concat(Enumerable.Repeat("=", header.Length)));
                writer.WriteLine();

                // Output string table
                writer.WriteLine("; String table");
                foreach (var str in result.StringTable)
                {
                    writer.WriteLine(Sanitise.GenerateLabel(args[2], str.Key) + ": dc.b \"" + Sanitise.SanitiseText(str.Value.text) + "\",0");
                }

                writer.WriteLine("\teven");

                writer.WriteLine("");

                // Output program
                writer.WriteLine("; Programs");
                foreach (var node in result.Program.Nodes)
                {
                    writer.WriteLine(Sanitise.GenerateLabel(args[2], node.Key) + ":");

                    Dictionary<int, string> labels = new Dictionary<int, string>();
                    foreach (var label in node.Value.Labels)
                        labels[label.Value] = label.Key;

                    for (int i = 0; i < node.Value.Instructions.Count; i++)
                    {
                        if (labels.ContainsKey(i))
                            writer.WriteLine("\t@" + labels[i] + ":");

                        var instruction = node.Value.Instructions[i];
                        Instructions.ByOpcode[(int)instruction.Opcode](args[2], instruction, writer);
                    }

                    writer.WriteLine("\trts\n");
                }
            }

            return 0;
        }
    }
}
