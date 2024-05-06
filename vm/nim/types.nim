import sequtils
import strformat
import tables

type
    ValueKind* = enum 
        VK_Void, VK_String, VK_Int

proc valueKindFromString*(s: string): ValueKind =
    case s:
    of "void": return VK_Void
    of "string": return VK_String
    of "int": return VK_Int
    else: return VK_Void

type
    Value* = object
        case kind*: ValueKind
        of VK_Void: discard
        of VK_String: s*: string
        of VK_Int: i*: int

proc `$`*(v: Value): string =
    case v.kind:
    of VK_Void: return "void"
    of VK_String: return fmt"{VK_String}({v.s})" # TODO: escape v.s
    of VK_Int: return fmt"{VK_Int}({v.i})"

type
    CpmKind* = enum
        Cmp_Eq
        Cmp_Neq
        Cmp_Lt
        Cmp_Gt
        Cmp_LtEq
        Cmp_GtEq

type
    InstructionKind* = enum
        Comment, Cmp,
        Dup, Swap, Cast,
        Pop, Push,
        Add, Sub, Mul, Div, Mod,
        Print,
        Label, Jump, EqJump, NeqJump, LtJump, GtJump,
        Call, Proc, ProcReturn, ProcArgs, ProcReturnArgs,
        Stor, Load,
        Unknown, Exit,

proc instructionKindFromString*(s: string): InstructionKind =
    case s:
    of "dup": return Dup
    of "swap": return Swap
    of "cast": return Cast
    
    of "pop": return Pop
    of "push": return Push
    
    of "add": return Add
    of "sub": return Sub
    of "mul": return Mul
    of "div": return Div
    of "mod": return Mod
    
    of "print": return Print
    
    of "label": return Label
    of "jump": return Jump
    of "eqjump": return EqJump
    of "neqjump": return NeqJump
    of "ltjump": return LtJump
    of "gtjump": return GtJump

    of "stor": return Stor
    of "load": return Load
    
    of "call": return Call
    of "proc": return Proc
    of "return": return ProcReturn
    of "|": return ProcArgs
    of ">": return ProcReturnArgs

    of "exit": return Exit
    of ";": Comment
    else: return Unknown

type
    Instruction* = object
        loc*: int
        case kind*: InstructionKind
        of Call, Proc:
            proc_ip*: int
            proc_name*: string
        of ProcReturn:
            return_target*: int
        of ProcArgs, ProcReturnArgs:
            args_count*: int
            args_types*: seq[ValueKind]
        of Cmp:
            cmp_kind*: CpmKind
        of Cast:
            type_target*: ValueKind
        of Dup, Pop, Swap: 
            value_target*: int
        of Push:
            operand*: Value
        of Label: 
            ip*: int
            name*: string
        of Jump, EqJump, NeqJump, LtJump, GtJump:
            name_target*: string
            target*: int
        of Stor, Load:
            key*: string
        of Exit:
            exit_code*: int
        of Unknown, Print, Add, Sub, Mul, Div, Mod, Comment:
            discard

type
    Program = ref object
        name*: string
        instructions*: seq[Instruction] = @[]

type
    LogLevel* = enum
        Log_Info, Log_Warning, Log_Error

type
    Stack* = ref object
        name*: string = ""
        values*: seq[Value] = @[]

proc `$`*(s: Stack): string = fmt"{s.values}"
proc add*(s: Stack, v: Value) = s.values.add(v)
proc get*(s: Stack, i: int): Value = s.values[i]
proc pop*(s: Stack): Value = s.values.pop
proc del*(s: Stack, i: int) = s.values.delete(i)
proc sub*(s: Stack, i: int, v: Value) = s.values[i] = v
proc len*(s: Stack): int = s.values.len

type
    ProcedureStack* = ref object
        stack*: Stack = Stack(name: "procedure")
        returns*: seq[ValueKind] = @[]

proc `$`*(s: ProcedureStack): string = fmt"{s.stack.values}"
proc add*(s: ProcedureStack, v: Value) = s.stack.values.add(v)
proc get*(s: ProcedureStack, i: int): Value = s.stack.values[i]
proc pop*(s: ProcedureStack): Value = s.stack.values.pop
proc del*(s: ProcedureStack, i: int) = s.stack.values.delete(i)
proc sub*(s: ProcedureStack, i: int, v: Value) = s.stack.values[i] = v
proc len*(s: ProcedureStack): int = s.stack.values.len

type
    Machine* = ref object
        ip*: int = 0
        entry*: int = -1
        
        procs*: Table[string, int] = initTable[string, int]()
        labels*: Table[string, int] = initTable[string, int]()
        variables*: Table[string, Value] = initTable[string, Value]()

        general_stack*: Stack = Stack(name: "general")
        procedures_stack*: seq[ProcedureStack] = @[]
        procedures_returns*: seq[int] = @[]

        program*: Program = Program()

proc stack*(m: Machine): Stack =
    if m.procedures_stack.len == 0: m.general_stack
    else: m.procedures_stack[m.procedures_stack.len - 1].stack

proc log*(m: Machine, loc: int, level: LogLevel, msg: string) =
    let logLevel = case level:
        of Log_Info: "INFO"
        of Log_Warning: "WARNING"
        of Log_Error: "ERROR"

    echo fmt("{logLevel}: {m.program.name}:{loc}:0: {msg}") # TODO: add column
    if level == Log_Error: quit 1

proc dump*(m: Machine) =
    echo fmt"IP: {m.ip}"
    echo fmt"Entry: {m.entry}"
    echo fmt"Procs: {m.procs.len}"
    echo fmt"Labels: {m.labels.len}"
    echo fmt"Stack: {m.general_stack.name}: {m.general_stack.values}"

    let procedures = m.procedures_stack.map(proc (ps: ProcedureStack): string = fmt"{ps.stack.name}: {ps.stack.values}")
    echo fmt"Procedures Stacks: {procedures}"

    let instructions = m.program.instructions
    echo fmt"Program Instructions: {m.program.name}: {instructions}"

proc trace*(m: Machine, i: Instruction) =
    echo fmt"TRACE: IP({m.ip}) INSTRUCTION_KIND({i.kind}): {i}"