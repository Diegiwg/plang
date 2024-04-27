import os
import strutils
import strformat

type
    ValueKind = enum 
        VK_Void, VK_String, VK_Int

    Value = object
        case kind: ValueKind  
        of VK_Void: v: void
        of VK_String: s: string
        of VK_Int: i: int

    InstructionKind = enum
        Pop, Push, Add, Print, Label

    Instruction = object
        loc: int
        case kind: InstructionKind
        of Pop: discard
        of Push: operand: Value
        of Add: discard
        of Print: discard
        of Label: ip: int

    Machine = ref object
        programName: string
        program: seq[Instruction] = @[]
        stack: seq[Value] = @[]
        ip: int = 0

    LogLevel = enum
        Log_Info, Log_Warning, Log_Error

proc log(m: Machine, loc: int, level: LogLevel, msg: string) =
    let logLevel = case level:
        of Log_Info: "INFO"
        of Log_Warning: "WARNING"
        of Log_Error: "ERROR"

    echo fmt("{logLevel}: {m.programName}:{loc}:0: {msg}") # TODO: add column
    if level == Log_Error: quit 1

proc compile(m: Machine, source: string) =
    var instructionCount = 0
    var lineCount = 0

    for line in source.splitLines():
        inc lineCount
        if line.len == 0: continue

        let parts = line.splitWhitespace()
        if parts.len == 0: continue

        case parts[0]:
        of "label":
            m.program.add(Instruction(loc: lineCount, kind: Label, ip: instructionCount))
        of "pop":
            m.program.add(Instruction(loc: lineCount, kind: Pop))
        of "push":
            m.program.add(Instruction(loc: lineCount, kind: Push, operand: Value(kind: VK_Int, i: parseInt(parts[1]))))
        of "add":
            m.program.add(Instruction(loc: lineCount, kind: Add))
        of "print":
            m.program.add(Instruction(loc: lineCount, kind: Print))
        else:
            m.log(lineCount, Log_Warning, fmt("Unknown instruction '{parts[0]}' skipped"))
            continue

        inc instructionCount

proc run(m: Machine) =
    while m.ip < len(m.program):
        let instruction = m.program[m.ip]

        case instruction.kind:
        of Label: discard

        of Print:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "No value on stack to print")
            let value = m.stack.pop()
            case value.kind:
            of VK_Void: echo "void"
            of VK_String: echo value.s
            of VK_Int: echo value.i

        of Pop:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "No value on stack to pop")
            discard m.stack.pop

        of Push:
            m.stack.add(instruction.operand)

        of Add:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "Not enough values on stack for + operation")
            let a = m.stack.pop
            let b = m.stack.pop
            if a.kind != b.kind: m.log(instruction.loc, Log_Error, "Incompatible types for + operation")
            m.stack.add(Value(kind: VK_Int, i: a.i + b.i))

        inc m.ip

when isMainModule:
    let argv = commandLineParams()

    if len(argv) == 0:
        echo "Missing file path"
        quit(1)
    
    if not fileExists(argv[0]):
        echo "File not found: ", argv[0]
        quit(1)

    let source: string = readFile(argv[0])
    if source.len == 0:
        echo "File is empty: ", argv[0]
        quit(1)

    var m = Machine()
    m.programName = argv[0]

    m.compile(source)
    m.run()