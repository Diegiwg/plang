label count
    push "Count: "
    dup 1
    cast string
    add
    print
    jump f

label entry
    push "Count from 1 to 10"
    print
    push ""
    print

    push 1
    jump count

    label f
    push 10
    eqjump finish
    jump inc

label inc
    push 1
    add
    jump count

label finish
    push ""
    print
    push "Done!"
    print
    exit 0