#!/bin/bash

# Compile the assembly file
gcc main.s -no-pie -o main.o

# Check if the compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful."
    # Check for the -d flag
    if [ "$1" == "-d" ]; then
        echo "Running the program with gdb..."
        gdb -ex "layout asm" -ex "break main" ./main.o
    else
        echo "Running the program..."
        ./main.o
    fi
else
    echo "Compilation failed."
fi