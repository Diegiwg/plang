proc sum
    | int int int
    > int int

    add

    return

proc calc
    | int
    > void

    push "Calculation result: "
    dup 1
    cast string
    add

    print
    pop

    return

label entry
    push "Trash"
    push "Trash"
    push 5
    push 5
    call sum
    call calc
    pop
    pop