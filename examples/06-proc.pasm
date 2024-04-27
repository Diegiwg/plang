proc hello
    | void
    > void

    push "Hello, World!"
    print

    return

label entry
    call hello

    push "Done!"
    print
    
    exit 0