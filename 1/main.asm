BITS 64
global _start

%include "../common.asm"

section .text

_start:
	mov rdi, [p1input]
	call read_input_file

	xor r12, r12               ; max_calories
	xor rbx, rbx               ; cursor
	mov rbp, input_file_buffer ; base
	main_loop:                 ; while (cursor < input_file_buffer_size)
	cmp rbx, [input_file_buffer_size]
	jae main_loop_end

	eat_whitespace:            ; while (cursor < input_file_buffer_size && is_whitespace(*(base + cursor))) ++cursor;
	cmp rbx, [input_file_buffer_size]
	jae main_loop_end
	xor r14, r14
	mov r15b, BYTE [rbp + rbx]
	sub r15, 0x9               ; map ['\t','\r'], which is [0x9,0xD], to [0x0,0x4], this makes the first 5 nonnegative values all whitespace
	cmp r15, 0x5
	setb r14b
	cmp r15, 0x17              ; ' ', which is 0x20, sub 0x9 is 0x17
	sete r15b
	or r14, r15
	cmp r14, 0
	je done_eating_whitespace
	inc rbx
	jmp eat_whitespace
	done_eating_whitespace:

	xor r13, r13 ; calories
	count_calories:
	cmp rbx, [input_file_buffer_size]
	jae done_counting_calories
	mov r14b, BYTE [rbp + rbx]
	cmp r14, 0x0A ; \n
	je done_counting_calories

	mov r15, rbx ; base pointer for calory string

	eat_number:
	cmp rbx, [input_file_buffer_size]
	jae done_eating_number
	mov r14b, BYTE [rbp + rbx]
	cmp r14, 0x0A ; \n
	je done_eating_number
	inc rbx
	jmp eat_number
	done_eating_number:

	mov rdi, r15         ; base pointer for calory string
	mov rsi, rbx
	sub rsi, r15         ; string length
	call parse_u64
	cmp eax, 1
	je parsed_u64_successfully
	mov rdi, failed_to_parse_number
	call error_and_exit
	parsed_u64_successfully:

	add r13, rdx ; add newly parsed calories to the total

	inc rbx ; skip newline after eating number, going past end of buffer is not a problem
	jmp count_calories
	done_counting_calories:

	cmp r12, r13
	cmovb r12, r13 ; max_calories = max(max_calories, calories)

	jmp main_loop
	main_loop_end:

	mov rdi, r12
	call print_u64

	mov rax, 60     ; sys_exit
	mov rdi, 0      ; exit code
	syscall

section .data
	p1in:         db "./p1in.txt",0
	p1in_example: db "./p1in_example.txt",0
	p1input:      dq p1in_example

	failed_to_parse_number: db "Failed to parse number",0
