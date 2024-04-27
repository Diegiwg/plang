# Simple Virtual Machine for PLang

This project demonstrates the implementation of a simple virtual machine (VM), capable of executing a custom assembly language, called `PLang`, with file extensions `.pasm`.

## Requirements

- At the moment, have the NIM language installed and working on your computer.
- Be using a Linux distribution.

## How to Test

- Clone the repository: `git clone https://github.com/Diegiwg/plang`
- Make the `run` executable: `chmod +x run`
- Execute `./run nim-test`

## Basic PLang Language (asm)

- For examples, access the `examples` folder.

## Documentation

The PLang language is designed to be simple, allowing for the creation of custom assembly programs. It supports a variety of instructions for stack manipulation, arithmetic operations, control flow, and procedure calls.

### Language Features

- **Stack Manipulation**: Instructions for pushing values onto the stack, popping values from the stack, and duplicating values on the stack.
- **Arithmetic Operations**: Support for basic arithmetic operations such as addition, subtraction, multiplication, division, and modulus.
- **Control Flow**: Instructions for jumping to labels, conditional jumps based on equality, inequality, greater than, and less than comparisons.
- **Procedure Calls**: Support for defining and calling procedures, including handling of procedure arguments and return values.
- **Type Casting**: Instructions for casting values from one type to another.
- **Printing**: Instruction for printing values from the stack.
- **Exit**: Instruction for exiting the program with a specified exit code.

### Example Program

A simple PLang program might look like this:

```asm
label entry
    push 5
    push 10
    add
    print
    exit 0
```

This program pushes the numbers 5 and 10 onto the stack, adds them together, prints the result, and then exits the program.

### Running a PLang Program

To run a PLang program, you would use the `run` script included in the repository, specifying the path to your `.pasm` file as an argument. For example:

```bash
./run nim ./my_program.pasm
```

This would execute the `my_program.pasm` file using the PLang Virtual Machine.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
