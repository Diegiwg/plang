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
        Unknown, Cast, Dup, Pop, Push, Add, Print, Label

    Instruction = object
        loc: int
        case kind: InstructionKind
        of Unknown: discard
        of Cast: type_target: ValueKind
        of Dup: value_target: int
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

proc strToValueKind(s: string): ValueKind =
    case s:
    of "void": return VK_Void
    of "string": return VK_String
    of "int": return VK_Int
    else: return VK_Void

proc strToInstructionKind(s: string): InstructionKind =
    static:
        if ord(high(InstructionKind)) + 1 != 8:
            echo "ERROR: InstructionKind out of range"
            quit 1

    case s:
    of "unknown": return Unknown
    of "cast": return Cast
    of "dup": return Dup
    of "pop": return Pop
    of "push": return Push
    of "add": return Add
    of "print": return Print
    of "label": return Label
    else: return Unknown

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

        let cmd = strToInstructionKind(parts[0])
        case cmd:
        of Cast:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "Missing operand for `cast` instruction")
            if parts[1].len < 0: m.log(lineCount, Log_Error, "Invalid operand for `cast` instruction")
            
            var target: ValueKind = strToValueKind(parts[1])
            if target == VK_Void: m.log(lineCount, Log_Error, "Invalid operand for `cast` instruction")

            m.program.add(Instruction(loc: lineCount, kind: Cast, type_target: target))

        of Dup:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "Missing operand for `dup` instruction")
            if parts[1].len < 0: m.log(lineCount, Log_Error, "Invalid operand for `dup` instruction") 
            
            var target: int
            try: target = parseInt(parts[1])
            except: m.log(lineCount, Log_Error, "Invalid operand for `dup` instruction")
                
            m.program.add(Instruction(loc: lineCount, kind: Dup, value_target: target))

        of Label:
            m.program.add(Instruction(loc: lineCount, kind: Label, ip: instructionCount))

        of Pop:
            m.program.add(Instruction(loc: lineCount, kind: Pop))

        of Push:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "Missing operand for `push` instruction")

            var value: Value = Value(kind: VK_Void)

            if value.kind == VK_Void:
                try: value = Value(kind: VK_Int, i: parseInt(parts[1]))
                except: discard

            let rest: string = join(parts[1..^1], " ")
            if value.kind == VK_Void:
                if rest[0] == '"' and rest[^1] == '"':
                    value = Value(kind: VK_String, s: rest[1..^2])

            if value.kind == VK_Void: m.log(lineCount, Log_Error, fmt("Unknown operand `{rest}` for `push` instruction. `{VK_Void}` assumed"))

            m.program.add(Instruction(loc: lineCount, kind: Push, operand: value))

        of Add:
            m.program.add(Instruction(loc: lineCount, kind: Add))

        of Print:
            m.program.add(Instruction(loc: lineCount, kind: Print))

        of Unknown:
            m.log(lineCount, Log_Error, fmt("Unknown instruction `{cmd}` skipped"))

        inc instructionCount

proc run(m: Machine) =
    while m.ip < len(m.program):
        let instruction = m.program[m.ip]

        case instruction.kind:
        of Cast:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "No value on stack to cast")

            let value = m.stack.pop()
            case value.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, "Casting `{VK_Void}` is not allowed")
            of VK_Int:
                case instruction.type_target:
                of VK_Void: m.log(instruction.loc, Log_Error, "Casting `{VK_Void}` is not allowed")
                of VK_Int: m.log(instruction.loc, Log_Warning, "Casting `{VK_Int}` to `{VK_Int}` does nothing")
                of VK_String: m.stack.add(Value(kind: VK_String, s: $value.i))
            of VK_String:
                case instruction.type_target:
                of VK_Void: m.log(instruction.loc, Log_Error, "Casting `{VK_Void}` is not allowed")
                of VK_String: m.log(instruction.loc, Log_Warning, "Casting `{VK_String}` to `{VK_String}` does nothing")
                of VK_Int:
                    try: m.stack.add(Value(kind: VK_Int, i: parseInt(value.s)))
                    except: m.log(instruction.loc, Log_Error, "Casting `{VK_String}: {value.s}` to `{VK_Int}` failed")

        of Dup:
            let target = m.stack.len - instruction.value_target - 1
            if target < 0 or target >= m.stack.len: m.log(instruction.loc, Log_Error, "Trying to duplicate value out of stack")
            m.stack.add(m.stack[target])

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
        
        of Unknown:
            m.log(instruction.loc, Log_Error, fmt("Unknown instruction"))

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