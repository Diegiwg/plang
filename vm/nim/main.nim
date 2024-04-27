import os
import strutils
import strformat

import types
import compile
import execute

when isMainModule:
    let argv = commandLineParams()

    if len(argv) == 0:
        echo "Usage: plang <file.pasm>"
        quit 1
    
    let sourcePath = argv[0]
    
    if not fileExists(sourcePath):
        echo fmt"File not found: `{sourcePath}`"
        quit 1

    if not sourcePath.endsWith(".pasm"):
        echo fmt"File is not .pasm: `{sourcePath}`"
        quit 1

    let source: string = readFile(sourcePath)
    if source.len == 0:
        echo fmt"File is empty: `{sourcePath}`"
        quit 1

    var m = Machine()
    m.programName = sourcePath

    m.compile(source)
    m.execute()