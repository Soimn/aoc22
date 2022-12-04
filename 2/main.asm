BITS 64
global _start

%include "../common.asm"

section .text

_start:
	mov rdi, [p1input]
	call read_input_file

	sub rsp, 0x10
	mov QWORD [rsp + 0], 0 ; total point count for part 1
	mov QWORD [rsp + 8], 0 ; total point count for part 2

	mov rbp, input_file_buffer
	mov rbx, 0
	round_loop:
	mov r12, [input_file_buffer_size]
	sub r12, rbx
	cmp r12, 4
	jb round_loop_end

	part_1:
	movzx r12, BYTE [rbp + rbx]
	movzx r13, BYTE [rbp + rbx + 2]

	sub r12, 'A'
	sub r13, 'X'

	lea r15, [r13 + 1]

	cmp r12, r13
	jne not_equal
	add r15, 3
	jmp score_tally_end
	not_equal:

	mov r14, 2
	sub r13, 1
	cmovs r13, r14
	cmp r12, r13
	jne score_tally_end
	add r15, 6

	score_tally_end:

	mov r14, QWORD [rsp]
	add r14, r15
	mov QWORD [rsp], r14

	part_2:
	movzx r12, BYTE [rbp + rbx]
	movzx r13, BYTE [rbp + rbx + 2]

	sub r12, 'A'
	sub r13, 'Y' ;  'X','Y','Z' => -1,0,1

	mov r14, 2
	mov r15, 0
	add r12, r13
	cmovs r12, r14
	cmp r12, 3
	cmove r12, r15

	lea r15, [r12 + 1]
	inc r13
 	imul r13, r13, 3
	add r15, r13

	mov r14, QWORD [rsp + 8]
	add r14, r15
	mov QWORD [rsp + 8], r14

	add rbx, 4
	jmp round_loop
	round_loop_end:

	mov rdi, part_1_colon
	call print
	mov rdi, QWORD [rsp]
	call print_u64
	mov rdi, newline_part_2_colon
	call print
	mov rdi, QWORD [rsp + 8]
	call print_u64
	mov rdi, newline
	call print

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
section .bss
	scoreboard: resb 8
