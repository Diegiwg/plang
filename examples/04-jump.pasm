label finish
exit 1

push "Jumping to `finish`"
print
jump finish

label hello
push "Hello, World!"
print
jump 1

label entry
push "Jumping to `hello`"
print
jump hello