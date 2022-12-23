; NOTE: This code is horrendously ugly, I was way too tired of dealing with strings to care

BITS 64
global _start

%include "../common.asm"

section .text

_start:
	mov rdi, [p1input]
	call read_input_file

	sub rsp, 0x10
	; 0x08 - width
	; 0x00 - initial max height

	mov rbp, input_file_buffer
	mov rbx, [input_file_buffer_size]
	xor r12, r12
	count_lines_until_stack_indices_loop:
	mov rdi, rbp
	mov rsi, rbx
	call eat_whitespace
	add rbp, rax
	sub rbx, rax

	cmp rbx, 0
	jle count_lines_until_stack_indices_loop_failed_to_parse

	movzx rdi, BYTE [rbp]
	call is_digit
	cmp eax, 1
	je count_lines_until_stack_indices_loop_end

	mov rdi, rbp
	mov rsi, rbx
	call eat_until_newline
	add rbp, rax
	sub rbx, rax
	inc r12
	jmp count_lines_until_stack_indices_loop

	count_lines_until_stack_indices_loop_failed_to_parse:
	mov rdi, failed_to_count_lines_of_drawing
	call print
	count_lines_until_stack_indices_loop_end:

	mov QWORD [rsp + 0x00], r12

	mov rdi, rbp
	mov rsi, rbx
	call eat_until_newline
	add rbp, rax
	sub rbx, rax

	backtrack_to_digit_loop:
	dec rbp
	inc rbx
	movzx rdi, BYTE [rbp]
	call is_digit
	cmp eax, 1
	je backtrack_to_digit_loop_end
	jmp backtrack_to_digit_loop
	backtrack_to_digit_loop_end:

	movzx r13, BYTE [rbp]
	sub r13, 0x30
	mov QWORD [rsp + 0x08], r13

	mov r15, r13
	imul r15, QWORD [rsp + 0x00]
	add r15, 8 + 7
	and r15, ~7
	mov r14, r15
	imul r15, r13
	add r15, 15
	and r15, ~15

	sub rsp, 0x20
	sub rsp, r15
	mov QWORD [rsp + 0x00], r12 ; 0x00 - initial height
	mov QWORD [rsp + 0x08], r13 ; 0x08 - width
	mov QWORD [rsp + 0x10], r14 ; 0x10 - line_size
	mov QWORD [rsp + 0x18], r15 ; 0x18 - extra stack space size
	                            ; 0x20 - scratch 1
	                            ; 0x28 - scratch 2

	lea rdi, [rsp + 0x30]
	mov rsi, QWORD [rsp + 0x18]
	call zero

	mov rbp, input_file_buffer
	xor rbx, rbx
	fill_array_loop:
	cmp rbx, QWORD [rsp + 0x00]
	jge fill_array_loop_end

	mov r15, -1
	fill_array_line_loop:
	inc r15
	cmp r15, QWORD [rsp + 0x08]
	jge fill_array_line_loop_end
	movzx r12, BYTE [rbp]
	add rbp, 4
	sub rbx, 4
	cmp r12, 0x20
	je fill_array_line_loop
	movzx r12, BYTE [rbp - 3]
	mov r13, QWORD [rsp + 0x10]
	imul r13, r15
	mov r14, QWORD [rsp + r13 + 0x30]
	inc r14
	mov QWORD [rsp + r13 + 0x30], r14
	lea r13, [r13 + r14 + 0x37]
	mov BYTE [rsp + r13], r12b
	jmp fill_array_line_loop
	fill_array_line_loop_end:
	movzx r12, BYTE [rbp]
	cmp r12, 0xD
	sete r12b
	add r12b, 1
	movzx r12, r12b
	add rbp, r12
	inc rbx
	jmp fill_array_loop
	fill_array_loop_end:

	mov r12, input_file_buffer
	mov rbx, [input_file_buffer_size]
	neg r12
	add r12, rbp
	sub rbx, r12
	mov rdi, rbp
	mov rsi, rbx
	call eat_until_newline
	add rbp, rax
	sub rbx, rax
	
	move_loop:
	mov rdi, rbp
	mov rsi, rbx
	call eat_whitespace
	add rbp, rax
	sub rbx, rax
	cmp rbx, 0
	jle move_loop_end
	add rbp, 5
	sub rbx, 5
	mov rdi, rbp
	mov rsi, rbx
	call eat_u64
	add rbp, rax
	sub rbx, rax
	mov r12, rdx
	movzx r13, BYTE [rbp + 6]
	movzx r14, BYTE [rbp + 11]
	add rbp, 12
	sub rbx, 12
	sub r13, 0x30
	sub r14, 0x30
	imul r13, QWORD [rsp + 0x10]
	imul r14, QWORD [rsp + 0x10]
	mov r15, QWORD [rsp + r13 + 0x30]
	sub r15, r12
	mov QWORD [rsp + r13 + 0x30], r15
	mov r15, QWORD [rsp + r14 + 0x30]
	add r15, r12
	mov QWORD [rsp + r14 + 0x30], r15
	mov r15, QWORD [rsp + r13 + 0x30]
	add r13, r15
	add r13, rsp
	mov r15, QWORD [rsp + r14 + 0x30]
	sub r15, r12
	add r14, r15
	add r14, rsp
	mov rdi, r13
	mov rsi, r14
	mov rcx, r12
	call copy
	jmp move_loop
	move_loop_end:

	mov rdi, part_1_colon
	call print
	xor r12, r12
	lea r13, [rsp + 0x30]
	print_part_1_loop:
	cmp r12, QWORD [rsp + 0x08]
	jge print_part_1_loop_end
	mov r15, QWORD [r13]
	cmp r15, 0
	je empty_stack
	dec r15
	add r15, r13
	movzx rdi, BYTE [r15]
	mov rsi, 1
	call print_w_len
	empty_stack:
	inc r12
	add r13, QWORD [rsp + 0x10]
	jmp print_part_1_loop
	print_part_1_loop_end:
	mov rdi, newline_part_2_colon
	call print
	mov rdi, -1
	call print_u64
	mov rdi, newline
	call print

	mov r12, QWORD [rsp + 0x18]
	lea rsp, [rsp + r12 + 0x30]

	exit:
	mov rax, 60     ; sys_exit
	mov rdi, 0      ; exit code
	syscall

section .data
	p1in:         db "./p1in.txt",0
	p1in_example: db "./p1in_example.txt",0
	p1input:      dq p1in_example

	part_1_colon:           db "Part 1: ",0
	newline_part_2_colon:   db 0x0A,"Part 2: ",0
	newline:                db 0x0A,0

	failed_to_count_lines_of_drawing: db "Failed to count lines of drawing",0xA,0

section .bss
	scoreboard: resb 8
