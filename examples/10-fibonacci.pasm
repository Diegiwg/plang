proc fibonacci
    | int
    > int

    push 2
    ltjump fibonacci_return

    dup
    push 1
    sub
    call fibonacci

    dup 1
    push 2
    sub
    call fibonacci

    add
    pop 1

    label fibonacci_return
    return

label entry
    push 20
    call fibonacci

    cast string
    pop

    push "fibonacci(20) = "
    swap 1
    add
    print

    exit 0
