label finish
    exit 0

push "Jumping to `finish`"
print
jump finish

label hello
    push "Hello, World!"
    print
    jump 2

label entry
    push "Jumping to `hello`"
    print
    jump hello