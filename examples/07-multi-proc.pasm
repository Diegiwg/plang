proc println
    | void
    > void
    push ""
    print
    return

proc sum
    | int int
    > string
    add
    cast string
    pop
    return

proc calc
    | string
    > void

    call println

    push "Calculation result: "
    dup 1
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