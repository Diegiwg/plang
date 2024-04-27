import strformat
import strutils
import tables

import types

proc execute*(m: Machine) =
    while m.ip < len(m.program.instructions):
        let instruction = m.program.instructions[m.ip]

        # m.trace(instruction)

        case instruction.kind:
        of Proc:
            m.procedures_stack.add(ProcedureStack())

        of ProcArgs:
            if m.procedures_stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: Not inside a procedure")
            var procedure_stack = m.procedures_stack.pop

            if instruction.args_count > 0 and m.stack.len < instruction.args_count:
                m.log(instruction.loc, Log_Error, 
                fmt"EXECUTE: Is expected {instruction.args_types} arguments from this procedure, got {m.stack}"
                )

            for arg in 0..<instruction.args_count:
                let stack_offset = m.stack.len - instruction.args_count
                let value = m.stack.get(stack_offset + arg)
                m.stack.del(stack_offset + arg)

                if value.kind != instruction.args_types[arg]:
                    m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for procedure argument. Expected `{instruction.args_types[arg]}`, got `{value.kind}`")

                procedure_stack.add(value)

            m.procedures_stack.add(procedure_stack)

        of ProcReturnArgs:
            if m.procedures_stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: Not inside a procedure")
            m.procedures_stack[m.procedures_stack.len - 1].returns = instruction.args_types

        of Call:
            if instruction.proc_name notin m.procs: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Procedure `{instruction.proc_name}` not found")

            m.procedures_returns.add(m.ip)
            m.ip = (m.procs[instruction.proc_name]) - 1
        
        of ProcReturn:
            if m.procedures_stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: Not inside a procedure")
            var procedure_stack = m.procedures_stack.pop

            if procedure_stack.len < procedure_stack.returns.len or (procedure_stack.len - procedure_stack.returns.len) != 0:
                m.log(instruction.loc, Log_Error, fmt"EXECUTE: Is expected {procedure_stack.returns} return values from this procedure, got {procedure_stack}")

            for arg in 0..<procedure_stack.returns.len:
                let stack_offset = procedure_stack.len - procedure_stack.returns.len
                let value = procedure_stack.get(stack_offset + arg)
                procedure_stack.del(stack_offset + arg)
                m.stack.add(value)

            m.ip = m.procedures_returns.pop

        of Cast:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: No value on stack to cast")

            let value = m.stack.pop()
            case value.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, "EXECUTE: Casting `{VK_Void}` is not allowed")
            of VK_Int:
                case instruction.type_target:
                of VK_Void: m.log(instruction.loc, Log_Error, "EXECUTE: Casting `{VK_Void}` is not allowed")
                of VK_Int: m.log(instruction.loc, Log_Warning, "EXECUTE: Casting `{VK_Int}` to `{VK_Int}` does nothing")
                of VK_String: m.stack.add(Value(kind: VK_String, s: $value.i))
            of VK_String:
                case instruction.type_target:
                of VK_Void: m.log(instruction.loc, Log_Error, "EXECUTE: Casting `{VK_Void}` is not allowed")
                of VK_String: m.log(instruction.loc, Log_Warning, "EXECUTE: Casting `{VK_String}` to `{VK_String}` does nothing")
                of VK_Int:
                    try: m.stack.add(Value(kind: VK_Int, i: parseInt(value.s)))
                    except: m.log(instruction.loc, Log_Error, "EXECUTE: Casting `{VK_String}: {value.s}` to `{VK_Int}` failed")

        of Dup:
            let target = m.stack.len - instruction.value_target - 1
            if target < 0 or target >= m.stack.len: m.log(instruction.loc, Log_Error, "EXECUTE: Trying to duplicate value out of stack")
            m.stack.add(m.stack.get(target))

        of Label: discard

        of Jump:
            if instruction.target != -1: 
                m.ip = instruction.target
                continue

            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            m.ip = m.labels[name]

        of EqJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `eqjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `eqjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i == b.i: true else: false
            of VK_String: goto = if a.s == b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]
        
        of NeqJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `neqjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `neqjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i != b.i: true else: false
            of VK_String: goto = if a.s != b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]

        of GtJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `gtjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `gtjump` operation. Try to compare `{b.kind}` with `{a.kind}`")
            
            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i > b.i: true else: false
            of VK_String: goto = if a.s > b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]

        of LtJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `ltjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `ltjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing `{VK_Void}` is not allowed")
            of VK_Int: goto = if a.i < b.i: true else: false
            of VK_String: goto = if a.s < b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = m.labels[name]
                
        of Print:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: No value on stack to print")
            let value = m.stack.pop()
            case value.kind:
            of VK_Void: echo "void"
            of VK_String: echo value.s
            of VK_Int: echo value.i

        of Pop:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: No value on stack to pop")
            discard m.stack.pop

        of Push:
            m.stack.add(instruction.operand)

        of Add:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `add` operation")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `add` operation. Try to add `{b.kind}` to `{a.kind}`")
            
            case a.kind:
            of VK_Int: m.stack.add(Value(kind: VK_Int, i: a.i + b.i))
            of VK_String: m.stack.add(Value(kind: VK_String, s: a.s & b.s))
            of VK_Void: discard
        
        of Exit:
            quit instruction.exit_code

        of Unknown:
            m.log(instruction.loc, Log_Error, fmt("EXECUTE: Unknown instruction"))

        inc m.ip

    if m.stack.len > 0:
        m.log(0, Log_Error, fmt"EXECUTE: Stack is not empty at end of program: {m.stack.len} value(s) on stack. Values: {m.stack.values}")