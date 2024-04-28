proc sum
    | int int
    > int
    add
    return

label entry
    push 1
    push 2
    call sum
    ;
    push "Sum is: "
    swap 1
    cast string
    pop
    add    
    print

