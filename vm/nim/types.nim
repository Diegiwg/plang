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
    InstructionKind* = enum
        Cast, 
        Dup,
        Pop, Push,
        Add,
        Print,
        Label, Jump, EqJump, NeqJump, LtJump, GtJump,
        Call, Proc, ProcReturn, ProcArgs, ProcReturnArgs,
        Unknown, Exit,

proc instructionKindFromString*(s: string): InstructionKind =
    case s:
    of "cast": return Cast
    
    of "dup": return Dup
    
    of "pop": return Pop
    of "push": return Push
    
    of "add": return Add
    
    of "print": return Print
    
    of "label": return Label
    of "jump": return Jump
    of "eqjump": return EqJump
    of "neqjump": return NeqJump
    of "ltjump": return LtJump
    of "gtjump": return GtJump
    
    of "call": return Call
    of "proc": return Proc
    of "return": return ProcReturn
    of "|": return ProcArgs
    of ">": return ProcReturnArgs

    of "exit": return Exit
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
        of Cast:
            type_target*: ValueKind
        of Dup: 
            value_target*: int
        of Push:
            operand*: Value
        of Label: 
            ip*: int
            name*: string
        of Jump, EqJump, NeqJump, LtJump, GtJump:
            name_target*: string
            target*: int
        of Exit:
            exit_code*: int
        of Unknown, Pop, Add, Print:
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

proc add*(s: Stack, v: Value) = s.values.add(v)
proc get*(s: Stack, i: int): Value = s.values[i]
proc pop*(s: Stack): Value = s.values.pop
proc len*(s: Stack): int = s.values.len

type
    Machine* = ref object
        ip*: int = 0
        entry*: int = -1
        
        procs*: Table[string, int] = initTable[string, int]()
        labels*: Table[string, int] = initTable[string, int]()

        general_stack*: Stack = Stack(name: "general")
        procedures_stack*: seq[Stack] = @[]
        procedures_returns*: seq[int] = @[]

        program*: Program = Program()

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

    let procedures = m.procedures_stack.map(proc(s: Stack): string = fmt"{s.name}: {s.values}")
    echo fmt"Procedures Stacks: {procedures}"

    let instructions = m.program.instructions
    echo fmt"Program Instructions: {m.program.name}: {instructions}"

proc trace*(m: Machine, i: Instruction) =
    echo fmt"TRACE: IP({m.ip}) INSTRUCTION_KIND({i.kind}): {i}"