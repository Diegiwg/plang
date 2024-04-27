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

type
    Stack = ref object
        values*: seq[Value] = @[]

proc add*(s: Stack, v: Value) = s.values.add(v)
proc get*(s: Stack, i: int): Value = s.values[i]
proc pop*(s: Stack): Value = s.values.pop
proc len*(s: Stack): int = s.values.len

type
    InstructionKind* = enum
        Unknown, Exit, Cast, Dup, Pop, Push, Add, Print, Label, Jump, EqJump, NeqJump, LtJump, GtJump, Proc, Return

proc instructionKindFromString*(s: string): InstructionKind =
    case s:
    of "exit": return Exit
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
    of "proc": return Proc
    of "return": return Return
    else: return Unknown

type
    Instruction* = object
        loc*: int
        case kind*: InstructionKind
        of Unknown, Pop, Add, Print, Proc, Return:
            discard
        of Exit:
            exit_code*: int
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

type
    Program = ref object
        name*: string
        instructions*: seq[Instruction] = @[]

type
    Machine* = ref object
        ip*: int = 0
        entry*: int = -1
        labels*: Table[string, int] = initTable[string, int]()

        general_stack*: Stack = Stack()
        procedures_stack*: seq[Stack] = @[]

        program*: Program = Program()

type
    LogLevel* = enum
        Log_Info, Log_Warning, Log_Error

proc log*(m: Machine, loc: int, level: LogLevel, msg: string) =
    let logLevel = case level:
        of Log_Info: "INFO"
        of Log_Warning: "WARNING"
        of Log_Error: "ERROR"

    echo fmt("{logLevel}: {m.program.name}:{loc}:0: {msg}") # TODO: add column
    if level == Log_Error: quit 1