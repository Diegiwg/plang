# Simple's Virtual Machine for PLang

This project demonstrates the implementation of a simple virtual machine (VM) in Multi-language, capable of executing a custom assembly language, called `PLang`, with file extensions `.pasm`.

The VM supports basic operations such as pushing and popping values from a stack, casting values, duplicating values, jumping to labels, and basic arithmetic operations.

## Features

- **Custom Assembly Language**: The VM executes a custom assembly language defined by a set of instructions.
- **Stack-Based Operations**: Supports basic stack operations like push, pop, and arithmetic operations.
- **Type Checking**: Ensures operations are performed on compatible types.
- **Labels and Jumps**: Supports defining labels and jumping to them.
- **Logging**: Includes a basic logging mechanism to report errors and warnings.

## Objective

To implement a virtual machine (VM) capable of executing the `PLang` language in various programming languages.

## Usage

Ensure you have the base language installed.

Run the command below in the project root:

```bash
./run {base-lang-name}-test
```

All example files will be executed using the chosen VM implementation.
