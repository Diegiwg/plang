import strformat
import strutils
import tables

import types
import utils

proc compile*(m: Machine, source: string) =
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
            let name = parts[1]
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "Missing operand for `label` instruction")
            if name in m.labels: m.log(lineCount, Log_Error, fmt("Duplicate label `{name}`"))

            if name == "entry":
                if m.entry != -1: m.log(lineCount, Log_Error, "Duplicate `entry` label")
                m.entry = instructionCount
            
            m.labels[name] = instructionCount
            m.program.add(Instruction(loc: lineCount, kind: Label, ip: instructionCount, name: name))

        of Jump:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "Missing operand for `jump` instruction")

            var target: int = -1
            try: target = parseInt(parts[1])
            except: discard

            var name: string = ""
            if target == -1:
                name = parts[1]
                if name == "entry": m.log(lineCount, Log_Error, "Cannot jump to `entry` label")
                
            m.program.add(Instruction(loc: lineCount, kind: Jump, name_target: name, target: target))
        
        of EqJump, NeqJump, LtJump, GtJump:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, fmt"Missing operand for `{parts[0]}` instruction")

            var name: string = parts[1]
            if name == "entry": m.log(lineCount, Log_Error, "Cannot jump to `entry` label")
            
            m.program.add(Instruction(loc: lineCount, kind: cmd, name_target: name, target: -1))

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

        of Exit:
            if parts.len < 2 or parts[1].len == 0: m.log(lineCount, Log_Error, "Missing operand for `exit` instruction")
            try: m.program.add(Instruction(loc: lineCount, kind: Exit, exit_code: parseInt(parts[1])))
            except: m.log(lineCount, Log_Error, "Invalid operand for `exit` instruction")

        of Unknown:
            m.log(lineCount, Log_Error, fmt("Unknown instruction `{cmd}` skipped"))

        inc instructionCount
    
    if m.entry == -1: m.log(0, Log_Error, "No `entry` label found")
    m.ip = m.labels["entry"]