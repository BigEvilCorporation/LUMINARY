using System;
using System.Collections.Generic;
using System.Text;

namespace YarnToLuminary
{
    static class Instructions
    {
        public delegate void Instruction(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer);

        public static readonly Instruction[] ByOpcode =
        {
            JumpTo,
            Jump,
            RunLine,
            RunCommand,
            AddOption,
            ShowOptions,
            PushString,
            PushFloat,
            PushBool,
            PushNull,
            JumpIfFalse,
            Pop,
            CallFunc,
            PushVariable,
            StoreVariable,
            Stop,
            RunNode
        };

        // Jumps to a named position in the node.
        // opA = string: label name
        static void JumpTo(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_JUMPTO " + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Peeks a string from stack, and jumps to that named position in the node.
        // No operands.
        static void Jump(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_JUMP");
        }

        // Delivers a string ID to the client.
        // opA = string: string ID
        static void RunLine(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_RUNLINE #" + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Delivers a command to the client.
        // opA = string: command text
        static void RunCommand(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_RUNCOMMAND " + instruction.Operands[0].StringValue);
        }

        // Adds an entry to the option list (see ShowOptions).
        /// - opA = string: string ID for option to add
        /// - opB = string: destination to go to if this option is selected
        /// - opC = number: number of expressions on the stack to insert
        ///   into the line
        /// - opD = bool: whether the option has a condition on it (in which
        ///   case a value should be popped off the stack and used to signal
        ///   the game that the option should be not available)
        static void AddOption(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_ADDOPTION #" + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue) + ", #" + Sanitise.GenerateLabel(programName, instruction.Operands[1].StringValue));
        }

        // Presents the current list of options to the client, then clears the list. The most recently selected option will be on the top of the stack when execution resumes.
        // No operands.
        static void ShowOptions(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_SHOWOPTIONS");
        }

        // Pushes a string onto the stack.
        // opA = string: the string to push to the stack.
        static void PushString(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_PUSHSTRING #" + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Pushes a floating point number onto the stack.
        // opA = float: number to push to stack
        static void PushFloat(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_PUSHNUMBER " + (int)float.Parse(instruction.Operands[0].StringValue));
        }

        // Pushes a boolean onto the stack.
        // opA = bool: the bool to push to stack
        static void PushBool(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            bool val = bool.Parse(instruction.Operands[0].StringValue);
            writer.WriteLine("\tYARN_PUSHBOOL " + (val ? "1" : "0"));
        }

        // Pushes a null value onto the stack.
        // No operands.
        static void PushNull(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_PUSHNULL");
        }

        // zero or false.
        // opA = string: label name
        static void JumpIfFalse(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_JUMPIFFALSE " + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Discards top of stack.
        // No operands.
        static void Pop(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_POP");
        }

        // Calls a function.
        // opA = string: name of the function
        static void CallFunc(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_CALLFUNC " + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Pushes the contents of a variable onto the stack.
        // opA = name of variable
        static void PushVariable(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_PUSHVARIABLE " + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Stores the contents of the top of the stack in the named variable.
        // opA = name of variable
        static void StoreVariable(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_STOREVARIABLE " + Sanitise.GenerateLabel(programName, instruction.Operands[0].StringValue));
        }

        // Stops execution of the program.
        // No operands.
        static void Stop(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_STOP");
        }

        // Run the node whose name is at the top of the stack.
        // No operands.
        static void RunNode(string programName, Yarn.Instruction instruction, System.IO.StreamWriter writer)
        {
            writer.WriteLine("\tYARN_RUNNODE");
        }
    }
}
