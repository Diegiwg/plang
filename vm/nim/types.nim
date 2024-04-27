import tables

type
    ValueKind* = enum 
        VK_Void, VK_String, VK_Int

    Value* = object
        case kind*: ValueKind
        of VK_Void: discard
        of VK_String: s*: string
        of VK_Int: i*: int

    InstructionKind* = enum
        Unknown, Exit, Cast, Dup, Pop, Push, Add, Print, Label, Jump, EqJump, NeqJump, LtJump, GtJump

    Instruction* = object
        loc*: int
        case kind*: InstructionKind
        of Unknown: discard
        of Exit:
            exit_code*: int
        of Cast:
            type_target*: ValueKind
        of Dup: 
            value_target*: int
        of Pop: discard
        of Push:
            operand*: Value
        of Add: discard
        of Print: discard
        of Label: 
            ip*: int
            name*: string
        of Jump, EqJump, NeqJump, LtJump, GtJump:
            name_target*: string
            target*: int

    Machine* = ref object
        programName*: string
        program*: seq[Instruction] = @[]
        stack*: seq[Value] = @[]
        ip*: int = 0
        entry*: int = -1
        labels*: Table[string, int] = initTable[string, int]()

    LogLevel* = enum
        Log_Info, Log_Warning, Log_Error
