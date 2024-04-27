import sequtils
import strformat
import strutils
import tables

import types
import utils

proc execute*(m: Machine) =
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

        of Jump:
            if instruction.target != -1: 
                m.ip = instruction.target
                continue

            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"Label `{name}` not found")

            m.ip = m.labels[name]

        of EqJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "Not enough values on stack for `eqjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"Incompatible types for `eqjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i == b.i: true else: false
            of VK_String: goto = if a.s == b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]
        
        of NeqJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "Not enough values on stack for `neqjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"Incompatible types for `neqjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i != b.i: true else: false
            of VK_String: goto = if a.s != b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]

        of GtJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "Not enough values on stack for `gtjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"Incompatible types for `gtjump` operation. Try to compare `{b.kind}` with `{a.kind}`")
            
            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i > b.i: true else: false
            of VK_String: goto = if a.s > b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]

        of LtJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "Not enough values on stack for `ltjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"Incompatible types for `ltjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i < b.i: true else: false
            of VK_String: goto = if a.s < b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]
                
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
        
        of Exit:
            quit instruction.exit_code

        of Unknown:
            m.log(instruction.loc, Log_Error, fmt("Unknown instruction"))

        inc m.ip

    if m.stack.len > 0:
        let values = m.stack.map(proc (v: Value): string = fmt"{v.kind}({v.i})").join(", ")
        m.log(0, Log_Error, fmt"Stack is not empty at end of program: {m.stack.len} value(s) on stack. Values: {values}")