BITS 64
global _start

%include "../common.asm"

section .text

_start:
	mov rdi, [p1input]
	call read_input_file

	sub rsp, 0x30
	; 0x28 r15 store
	; 0x20 r14 store
	; 0x18 r13 store
	; 0x10 r12 store
	mov QWORD [rsp + 0x08], 0
	mov QWORD [rsp + 0x00], 0

	mov rbp, input_file_buffer        ; cursor
	mov rbx, [input_file_buffer_size] ; len
	line_loop:
	cmp rbx, 0
	jle line_loop_end

	mov rdi, rbp
	mov rsi, rbx
	call eat_u64
	cmp eax, 0
	;je line_loop_end
	jle line_loop_parsing_failed
	add rbp, rax
	sub rbx, rax
	mov r12, rdx

	inc rbp
	dec rbx

	mov rdi, rbp
	mov rsi, rbx
	call eat_u64
	cmp eax, 0
	;je line_loop_end
	jle line_loop_parsing_failed
	add rbp, rax
	sub rbx, rax
	mov r13, rdx

	inc rbp
	dec rbx

	mov rdi, rbp
	mov rsi, rbx
	call eat_u64
	cmp eax, 0
	;je line_loop_end
	jle line_loop_parsing_failed
	add rbp, rax
	sub rbx, rax
	mov r14, rdx

	inc rbp
	dec rbx

	mov rdi, rbp
	mov rsi, rbx
	call eat_u64
	cmp eax, 0
	;je line_loop_end
	jle line_loop_parsing_failed
	add rbp, rax
	sub rbx, rax
	mov r15, rdx
	jmp line_loop_parsing_succeeded

	line_loop_parsing_failed:
	mov rdi, failed_to_parse
	call print
	jmp exit
	line_loop_parsing_succeeded:

	mov QWORD [rsp + 0x10], r12
	mov QWORD [rsp + 0x18], r13
	mov QWORD [rsp + 0x20], r14
	mov QWORD [rsp + 0x28], r15

	cmp r12, r14
	setle r12b
	setge r14b

	cmp r13, r15
	setge r13b
	setle r15b

	and r12b, r13b
	and r14b, r15b
	or r12b, r14b
	movzx r12, r12b

	mov r13, QWORD [rsp + 0x00]
	add r13, r12
	mov QWORD [rsp + 0x00], r13

	mov r12, QWORD [rsp + 0x10]
	mov r13, QWORD [rsp + 0x18]
	mov r14, QWORD [rsp + 0x20]
	mov r15, QWORD [rsp + 0x28]

	cmp r12, r15
	setg r12b
	cmp r13, r14
	setl r13b

	or r12b, r13b
	xor r12b, 1
	movzx r12, r12b
	
	mov r13, QWORD [rsp + 0x08]
	add r13, r12
	mov QWORD [rsp + 0x08], r13

	mov rdi, rbp
	mov rsi, rbx
	call eat_whitespace
	add rbp, rax
	sub rbx, rax

	jmp line_loop
	line_loop_end:

	mov rdi, part_1_colon
	call print
	mov rdi, QWORD [rsp + 0x00]
	call print_u64
	mov rdi, newline_part_2_colon
	call print
	mov rdi, QWORD [rsp + 0x08]
	call print_u64
	mov rdi, newline
	call print

	add rsp, 0x30
	exit:
	mov rax, 60     ; sys_exit
	mov rdi, 0      ; exit code
	syscall

section .data
	p1in:         db "./p1in.txt",0
	p1in_example: db "./p1in_example.txt",0
	p1input:      dq p1in

	part_1_colon:           db "Part 1: ",0
	newline_part_2_colon:   db 0x0A,"Part 2: ",0
	newline:                db 0x0A,0

	failed_to_parse:        db "Failed to parse",0xA,0
section .bss
	scoreboard: resb 8
