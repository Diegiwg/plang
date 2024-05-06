label entry

    push 1
    stor test ; now the value 1 poped from the stack is stored in the variable test
    push 2

    load test ; the value stored in the variable test is loaded to the stack
    print
    pop ; poped the value 2 that was left unchenged