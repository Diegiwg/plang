import os
import strutils

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
    case kind: InstructionKind
    of Pop: discard
    of Push: operand: Value
    of Add: discard
    of Print: discard
    of Label: loc: int

  Machine = ref object
    program: seq[Instruction] = @[]
    stack: seq[Value] = @[]
    ip: int = 0

proc compile(m: Machine, source: string) =
    var instructionCount = 0
    for line in source.splitLines():
        if line.len == 0: continue

        let parts = line.splitWhitespace()
        if parts.len == 0: continue

        case parts[0]:
        of "label":
            m.program.add(Instruction(kind: Label, loc: instructionCount))
        of "pop":
            m.program.add(Instruction(kind: Pop))
        of "push":
            m.program.add(Instruction(kind: Push, operand: Value(kind: VK_Int, i: parseInt(parts[1]))))
        of "add":
            m.program.add(Instruction(kind: Add))
        of "print":
            m.program.add(Instruction(kind: Print))
        else:
            echo "Unknown instruction '", parts[0], "' on line ", line
            continue

        inc instructionCount

proc run(m: Machine) =
    while m.ip < len(m.program):
        let instruction = m.program[m.ip]

        case instruction.kind:
        of Label: discard

        of Print:
            if m.stack.len == 0:
                echo "ERROR: Stack underflow"
                quit 1
            
            let value = m.stack.pop()
            case value.kind:
            of VK_Void: echo "void"
            of VK_String: echo value.s
            of VK_Int: echo value.i

        of Pop:
            if m.stack.len == 0:
                echo "ERROR: Stack underflow"
                quit 1
            
            discard m.stack.pop()

        of Push:
            m.stack.add(instruction.operand)

        of Add:
            if m.stack.len < 2:
                echo "ERROR: Stack underflow"
                quit 1
            
            let a = m.stack.pop()
            let b = m.stack.pop()

            if a.kind != b.kind:
                echo "ERROR: Incompatible types for + operation"
                quit 1

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

    m.compile(source)
    m.run()