#!/bin/bash
nasm -felf64 -g -F dwarf -Wall main.asm && ld -o main main.o
