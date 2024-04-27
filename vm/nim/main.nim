import os
import strutils
import strformat

type
    ValueKind = enum 
        VK_Void, VK_String, VK_Int

    Value = object
        case kind: ValueKind
        of VK_Void: discard
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

        let cmd = parts[0]
        case cmd:
        
        of "label":
            m.program.add(Instruction(loc: lineCount, kind: Label, ip: instructionCount))

        of "pop":
            m.program.add(Instruction(loc: lineCount, kind: Pop))

        of "push":
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Warning, "Missing operand for `push` instruction")

            var value: Value = Value(kind: VK_Void)

            if value.kind == VK_Void:
                try: value = Value(kind: VK_Int, i: parseInt(parts[1]))
                except: discard

            let rest: string = join(parts[1..^1], " ")
            if value.kind == VK_Void:
                if rest[0] == '"' and rest[^1] == '"':
                    value = Value(kind: VK_String, s: rest[1..^2])

            if value.kind == VK_Void: m.log(lineCount, Log_Warning, fmt("Unknown operand `{rest}` for `push` instruction. `{VK_Void}` assumed"))

            m.program.add(Instruction(loc: lineCount, kind: Push, operand: value))

        of "add":
            m.program.add(Instruction(loc: lineCount, kind: Add))

        of "print":
            m.program.add(Instruction(loc: lineCount, kind: Print))

        else:
            m.log(lineCount, Log_Warning, fmt("Unknown instruction `{cmd}` skipped"))
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
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "Not enough values on stack for `add` operation")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"Incompatible types for `add` operation. Try to add `{b.kind}` to `{a.kind}`")
            
            case a.kind:
            of VK_Int: m.stack.add(Value(kind: VK_Int, i: a.i + b.i))
            of VK_String: m.stack.add(Value(kind: VK_String, s: a.s & b.s))
            of VK_Void: discard

        inc m.ip

when isMainModule:
    let argv = commandLineParams()

    if len(argv) == 0:
        echo "Usage: plang <file.pasm>"
        quit 1
    
    let sourcePath = argv[0]
    
    if not fileExists(sourcePath):
        echo fmt"File not found: `{sourcePath}`"
        quit 1

    if not sourcePath.endsWith(".pasm"):
        echo fmt"File is not .pasm: `{sourcePath}`"
        quit 1

    let source: string = readFile(sourcePath)
    if source.len == 0:
        echo fmt"File is empty: `{sourcePath}`"
        quit 1

    var m = Machine()
    m.programName = sourcePath

    m.compile(source)
    m.run()