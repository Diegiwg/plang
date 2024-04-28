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

        of Cmp:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Is expected 2 values on stack, got {m.stack}")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `cmp` operation. Try to compare `{b.kind}` with `{a.kind}`")

            case instruction.cmp_kind:
            of Cmp_Eq:
                case a.kind:
                    of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_Void}`")
                    of VK_Int: m.stack.add(Value(kind: VK_Int, i: if a.i == b.i: 1 else: 0))
                    of VK_String: m.stack.add(Value(kind: VK_Int, i: if a.s == b.s: 1 else: 0))

            of Cmp_Neq:
                case a.kind:
                    of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_Void}`")
                    of VK_Int: m.stack.add(Value(kind: VK_Int, i: if a.i != b.i: 1 else: 0))
                    of VK_String: m.stack.add(Value(kind: VK_Int, i: if a.s != b.s: 1 else: 0))
            
            of Cmp_Gt:
                case a.kind:
                    of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_Void}`")
                    of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_String}`")
                    of VK_Int: m.stack.add(Value(kind: VK_Int, i: if a.i >= b.i: 1 else: 0))
            
            of Cmp_Lt:
                case a.kind:
                    of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_Void}`")
                    of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_String}`")
                    of VK_Int: m.stack.add(Value(kind: VK_Int, i: if a.i < b.i: 1 else: 0))

            of Cmp_GtEq:
                case a.kind:
                    of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_Void}`")
                    of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_String}`")
                    of VK_Int: m.stack.add(Value(kind: VK_Int, i: if a.i >= b.i: 1 else: 0))
            
            of Cmp_LtEq:
                case a.kind:
                    of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_Void}`")
                    of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparison is not allowed for `{VK_String}`")
                    of VK_Int: m.stack.add(Value(kind: VK_Int, i: if a.i <= b.i: 1 else: 0))

        of Cast:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, fmt"EXECUTE: No value on stack to cast")

            let value = m.stack.pop()
            case value.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Casting is not allowed for `{VK_Void}`")
            
            of VK_Int:
                case instruction.type_target:
                of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Casting is not allowed for `{VK_Void}`")

                of VK_Int:
                    m.log(instruction.loc, Log_Warning, fmt"EXECUTE: Casting `{VK_Int}` to `{VK_Int}` does nothing")
                    m.stack.add(Value(kind: VK_Int, i: value.i))
                    m.stack.add(Value(kind: VK_Int, i: 0))

                of VK_String:
                    m.stack.add(Value(kind: VK_String, s: $value.i))
                    m.stack.add(Value(kind: VK_Int, i: 1))
            
            of VK_String:
                case instruction.type_target:
                of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Casting is not allowed for `{VK_Void}`")

                of VK_String:
                    m.log(instruction.loc, Log_Warning, fmt"EXECUTE: Casting `{VK_String}` to `{VK_String}` does nothing")
                    m.stack.add(Value(kind: VK_String, s: value.s))
                    m.stack.add(Value(kind: VK_Int, i: 1))

                of VK_Int:
                    try:
                        m.stack.add(Value(kind: VK_Int, i: parseInt(value.s)))
                        m.stack.add(Value(kind: VK_Int, i: 1))

                    except:
                        m.log(instruction.loc, Log_Warning, fmt"EXECUTE: Casting `{VK_String}: {value.s}` to `{VK_Int}` failed")
                        m.stack.add(Value(kind: VK_Int, i: 1))

        of Dup:
            let target = m.stack.len - instruction.value_target - 1
            if target < 0 or target >= m.stack.len: m.log(instruction.loc, Log_Error, "EXECUTE: Trying to duplicate value out of stack")
            m.stack.add(m.stack.get(target))
        
        of Swap:
            let target = m.stack.len - instruction.value_target - 1
            if target < 0 or target >= m.stack.len: m.log(instruction.loc, Log_Error, "EXECUTE: Trying to swap value out of stack")
            
            let a = m.stack.pop
            m.stack.add(m.stack.get(target))
            m.stack.sub(target, a)

        of Label, Comment: discard

        of Jump:
            if instruction.target != -1: 
                m.ip = instruction.target
                continue

            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            m.ip = (m.labels[name]) - 1

        of EqJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `eqjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `eqjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing is not allowed for `{VK_Void}`")
            of VK_Int: goto = if a.i == b.i: true else: false
            of VK_String: goto = if a.s == b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = (m.labels[name]) - 1
        
        of NeqJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `neqjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `neqjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing is not allowed for `{VK_Void}`")
            of VK_Int: goto = if a.i != b.i: true else: false
            of VK_String: goto = if a.s != b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = (m.labels[name]) - 1

        of GtJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `gtjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `gtjump` operation. Try to compare `{b.kind}` with `{a.kind}`")
            
            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing is not allowed for `{VK_Void}`")
            of VK_Int: goto = if a.i > b.i: true else: false
            of VK_String: goto = if a.s > b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = (m.labels[name]) - 1

        of LtJump:
            let name = instruction.name_target
            if name == "" and name notin m.labels: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Label `{name}` not found")

            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `ltjump` operation")
            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `ltjump` operation. Try to compare `{b.kind}` with `{a.kind}`")

            var goto = false
            case a.kind:
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Comparing is not allowed for `{VK_Void}`")
            of VK_Int: goto = if a.i < b.i: true else: false
            of VK_String: goto = if a.s < b.s: true else: false
            
            m.stack.add(a)
            if goto: m.ip = (m.labels[name]) - 1
                
        of Print:
            if m.stack.len == 0: m.log(instruction.loc, Log_Error, "EXECUTE: No value on stack to print")
            let value = m.stack.pop()
            case value.kind:
            of VK_Void: echo "void"
            of VK_String: echo value.s
            of VK_Int: echo value.i

        of Pop:
            let target = m.stack.len - instruction.value_target - 1
            if target < 0 or target >= m.stack.len: m.log(instruction.loc, Log_Error, "EXECUTE: Trying to poping value out of stack")
            m.stack.del(target)

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
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Addition is not allowed for `{VK_Void}`")
        
        of Sub:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `sub` operation")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `sub` operation. Try to subtract `{b.kind}` from `{a.kind}`")

            case a.kind:
            of VK_Int: m.stack.add(Value(kind: VK_Int, i: a.i - b.i))
            of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Subtraction is not allowed for `{VK_String}`")
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Subtraction is not allowed for `{VK_Void}`")

        of Mul:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `mul` operation")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `mul` operation. Try to multiply `{b.kind}` with `{a.kind}`")

            case a.kind:
            of VK_Int: m.stack.add(Value(kind: VK_Int, i: a.i * b.i))
            of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Multiplication is not allowed for `{VK_String}`")
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Multiplication is not allowed for `{VK_Void}`")
        
        of Div:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `div` operation")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `div` operation. Try to divide `{b.kind}` by `{a.kind}`")

            if b.i == 0: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Division by zero")

            case a.kind:
            of VK_Int: m.stack.add(Value(kind: VK_Int, i: a.i div b.i))
            of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Division is not allowed for `{VK_String}`")
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Division is not allowed for `{VK_Void}`")

        of Mod:
            if m.stack.len < 2: m.log(instruction.loc, Log_Error, "EXECUTE: Not enough values on stack for `mod` operation")

            let b = m.stack.pop
            let a = m.stack.pop

            if a.kind != b.kind: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Incompatible types for `mod` operation. Try to divide `{b.kind}` by `{a.kind}`")

            if b.i == 0: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Division by zero")

            case a.kind:
            of VK_Int: m.stack.add(Value(kind: VK_Int, i: a.i mod b.i))
            of VK_String: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Modulo is not allowed for `{VK_String}`")
            of VK_Void: m.log(instruction.loc, Log_Error, fmt"EXECUTE: Modulo is not allowed for `{VK_Void}`")

        of Exit:
            quit instruction.exit_code

        of Unknown:
            m.log(instruction.loc, Log_Error, fmt("EXECUTE: Unknown instruction"))

        inc m.ip

    if m.stack.len > 0:
        m.log(0, Log_Error, fmt"EXECUTE: Stack is not empty at end of program: {m.stack.len} value(s) on stack. Values: {m.stack.values}")