label entry
    push 5
    push "5"
    cast int
    ; Result of cast in top of stack '0' for sucess and '1' for failure
    pop
    add

    push "Total: "
    dup 1
    cast string
    pop
    add

    print
    pop