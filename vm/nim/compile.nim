import strformat
import strutils
import tables

import types

proc compile*(m: Machine, source: string) =
    var instructionCount = 0
    var lineCount = 0

    for line in source.splitLines():
        inc lineCount
        if line.len == 0: continue

        let parts = line.splitWhitespace()
        if parts.len == 0: continue

        let cmd = instructionKindFromString(parts[0])
        case cmd:

        of Call:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing procedure name for `call` instruction")
            let name = parts[1]
            if name notin m.procs: m.log(lineCount, Log_Error, fmt"COMPILE: Procedure `{name}` not found")

            m.program.instructions.add(Instruction(loc: lineCount, kind: Call, proc_name: name))

        of Proc:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing name for `proc` instruction")
            let name = parts[1]

            m.procs[name] = instructionCount
            m.program.instructions.add(Instruction(loc: lineCount, kind: Proc, proc_name: name, proc_ip: instructionCount))
            
        of ProcReturn:
            m.program.instructions.add(Instruction(loc: lineCount, kind: ProcReturn, return_target: -1))
            
        of ProcArgs:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing Procedure Args. Try `| void` if no args are needed")

            var instruction = Instruction(loc: lineCount, kind: ProcArgs)
            
            for arg_type in parts[1..^1]:
                if arg_type == "void":
                    if instruction.args_types.len > 0: m.log(lineCount, Log_Error, "COMPILE: Try to mark {VK_Void} as an argument after other arguments. Try `| void` if no args are needed")
                    break

                instruction.args_types.add(valueKindFromString(arg_type))

            instruction.args_count = instruction.args_types.len

            m.program.instructions.add(instruction)

        of ProcReturnArgs:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing Procedure Return Args. Try `> void` if no args are needed")

            var instruction = Instruction(loc: lineCount, kind: ProcReturnArgs)
            
            for arg_type in parts[1..^1]:
                if arg_type == "void":
                    if instruction.args_types.len > 0: m.log(lineCount, Log_Error, "COMPILE: Try to mark {VK_Void} as an argument after other arguments. Try `| void` if no args are needed")
                    break

                instruction.args_types.add(valueKindFromString(arg_type))
            instruction.args_count = instruction.args_types.len

            m.program.instructions.add(instruction)

        of Cast:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing operand for `cast` instruction")
            if parts[1].len < 0: m.log(lineCount, Log_Error, "COMPILE: Invalid operand for `cast` instruction")
            
            var target: ValueKind = valueKindFromString(parts[1])
            if target == VK_Void: m.log(lineCount, Log_Error, "COMPILE: Invalid operand for `cast` instruction")

            m.program.instructions.add(Instruction(loc: lineCount, kind: Cast, type_target: target))

        of Dup:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing operand for `dup` instruction")
            if parts[1].len < 0: m.log(lineCount, Log_Error, "COMPILE: Invalid operand for `dup` instruction") 
            
            var target: int
            try: target = parseInt(parts[1])
            except: m.log(lineCount, Log_Error, "COMPILE: Invalid operand for `dup` instruction")
                
            m.program.instructions.add(Instruction(loc: lineCount, kind: Dup, value_target: target))

        of Label:
            let name = parts[1]
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing operand for `label` instruction")
            if name in m.labels: m.log(lineCount, Log_Error, fmt("COMPILE: Duplicate label `{name}`"))

            if name == "entry":
                if m.entry != -1: m.log(lineCount, Log_Error, "COMPILE: Duplicate `entry` label")
                m.entry = instructionCount
            
            m.labels[name] = instructionCount
            m.program.instructions.add(Instruction(loc: lineCount, kind: Label, ip: instructionCount, name: name))

        of Jump:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing operand for `jump` instruction")

            var target: int = -1
            try: target = parseInt(parts[1])
            except: discard

            var name: string = ""
            if target == -1:
                name = parts[1]
                if name == "entry": m.log(lineCount, Log_Error, "COMPILE: Cannot jump to `entry` label")
                
            m.program.instructions.add(Instruction(loc: lineCount, kind: Jump, name_target: name, target: target))
        
        of EqJump, NeqJump, LtJump, GtJump:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, fmt"COMPILE: Missing operand for `{parts[0]}` instruction")

            var name: string = parts[1]
            if name == "entry": m.log(lineCount, Log_Error, "COMPILE: Cannot jump to `entry` label")
            
            m.program.instructions.add(Instruction(loc: lineCount, kind: cmd, name_target: name, target: -1))

        of Push:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing operand for `push` instruction")

            var value: Value = Value(kind: VK_Void)

            if value.kind == VK_Void:
                try: value = Value(kind: VK_Int, i: parseInt(parts[1]))
                except: discard

            let rest: string = join(parts[1..^1], " ")
            if value.kind == VK_Void:
                if rest[0] == '"' and rest[^1] == '"':
                    value = Value(kind: VK_String, s: rest[1..^2])

            if value.kind == VK_Void: m.log(lineCount, Log_Error, fmt("COMPILE: Unknown operand `{rest}` for `push` instruction. `{VK_Void}` assumed"))

            m.program.instructions.add(Instruction(loc: lineCount, kind: Push, operand: value))

        of Add, Sub, Mul, Div, Mod, Print, Pop:
            m.program.instructions.add(Instruction(loc: lineCount, kind: cmd))

        of Exit:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "COMPILE: Missing operand for `exit` instruction")
            try: m.program.instructions.add(Instruction(loc: lineCount, kind: Exit, exit_code: parseInt(parts[1])))
            except: m.log(lineCount, Log_Error, "COMPILE: Invalid operand for `exit` instruction")

        of Unknown:
            m.log(lineCount, Log_Error, fmt("COMPILE: Unknown instruction `{cmd}` skipped"))

        inc instructionCount
    
    if m.entry == -1: m.log(0, Log_Error, "COMPILE: No `entry` label found")
    m.ip = m.labels["entry"]