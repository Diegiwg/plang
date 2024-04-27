import strformat

import types

proc strToValueKind*(s: string): ValueKind =
    case s:
    of "void": return VK_Void
    of "string": return VK_String
    of "int": return VK_Int
    else: return VK_Void

proc strToInstructionKind*(s: string): InstructionKind =
    static:
        if ord(high(InstructionKind)) != 13:
            echo fmt"ERROR: InstructionKind out of range. Current max: {ord(high(InstructionKind))}"
            quit 1

    case s:
    of "unknown": return Unknown
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
    else: return Unknown

proc log*(m: Machine, loc: int, level: LogLevel, msg: string) =
    let logLevel = case level:
        of Log_Info: "INFO"
        of Log_Warning: "WARNING"
        of Log_Error: "ERROR"

    echo fmt("{logLevel}: {m.programName}:{loc}:0: {msg}") # TODO: add column
    if level == Log_Error: quit 1