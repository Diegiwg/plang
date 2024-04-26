import os
import strutils

type
    Value = int

    Instruction = object
        operand: Value

    Machine = ref object
        ip: int = 0
        stack: seq[Instruction] = @[]

proc compileAndRun(m: Machine, asmFilePath: string) =
    let content: string = readFile(asmFilePath)
    let lines: seq[string] = content.split('\n')

    for line in lines:
        if len(line) == 0:
            continue

        var parts: seq[string] = line.split(' ')

        if len(parts) == 0:
            continue

        case parts[0]:
            of "pop":
                if len(m.stack) == 0:
                    echo "Stack underflow"
                    quit(1)
                
                m.stack.delete(m.stack.high)

            of "push":
                m.stack.add(Instruction(operand: parseInt(parts[1])))

            of "add":
                if len(m.stack) < 2:
                    echo "Stack underflow"
                    quit(1)

                let
                    a = m.stack[m.stack.high - 1]
                    b = m.stack[m.stack.high]

                m.stack[m.stack.high - 1] = Instruction(operand: a.operand + b.operand)
                m.stack.delete(m.stack.high)

            of "print":
                if len(m.stack) == 0:
                    echo "Stack underflow"
                    quit(1)
                
                echo m.stack[m.stack.high].operand
                m.stack.delete(m.stack.high)

            else:
                echo "Unknown instruction: " & parts[0]
                quit(1)
        
        inc(m.ip)

    if len(m.stack) > 0:
        echo "Data remaining on stack"
        quit(1)

when isMainModule:
    let argv = commandLineParams()

    if len(argv) == 0:
        echo "Missing file path"
        quit(1)

    var m = Machine()
    m.compileAndRun(argv[0])