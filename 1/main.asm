BITS 64
global _start

%include "../common.asm"

section .text

_start:
	mov rdi, [p1input]
	call read_input_file


	mov rax, 9     ; sys_mmap
	mov rdi, 0     ; 0 as address since I don't care where the memory is placed
	mov rsi, QWORD [input_file_buffer_size]
	shl rsi, 2     ; rsi = size of allocation, min file size for n elements f=2n-1 => n=(f-1)/2 => 8n=4f-4 < 4f
	mov rdx, 0x03  ; protection, PROT_READ = 0x1, PROT_WRITE = 
	mov r10, 0x22  ; flags, MAP_PRIVATE = 0x02, MAP_ANONYMOUS = 0x20
	mov r8,  -1    ; file descriptor, -1 since some systems may require it to be when MAP_ANONYMOUS is used
  mov r9,  0     ; offset
	syscall

	cmp rax, -1
	jne map_successful
	mov rdi, failed_to_map_memory
	call error_and_exit
	map_successful:
	sub rsp, 0x10
	mov QWORD [rsp + 8], rax   ; store scoreboard base first
	mov QWORD [rsp],     rax   ; scoreboard cursor second

	xor rbx, rbx               ; cursor
	mov rbp, input_file_buffer ; base
	main_loop:                 ; while (cursor < fer_size)
	cmp rbx, [input_file_buffer_size]
	jae main_loop_end

	eat_whitespace:            ; while (cursor < input_file_buffer_size && is_whitespace(*(base + cursor))) ++cursor;
	cmp rbx, [input_file_buffer_size]
	jae main_loop_end
	xor r14, r14
	movzx r15, BYTE [rbp + rbx]
	sub r15, 0x9               ; map ['\t','\r'], which is [0x9,0xD], to [0x0,0x4], this makes the first 5 nonnegative values all whitespace
	cmp r15, 0x5
	setb r14b
	cmp r15, 0x17              ; ' ', which is 0x20, sub 0x9 is 0x17
	sete r15b
	or r14b, r15b
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

	lea r15, [rbp + rbx] ; base pointer for calory string

	eat_number:
	cmp rbx, [input_file_buffer_size]
	jae done_eating_number
	movzx r14, BYTE [rbp + rbx]
	cmp r14, 0x0A ; \n
	je done_eating_number
	inc rbx
	jmp eat_number
	done_eating_number:

	mov rdi, r15         ; base pointer for calory string
	lea rsi, [rbp + rbx]
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

	mov r12, QWORD [rsp] ; load scoreboard cursor
	mov QWORD [r12], r13 ; store current calory count in scoreboard
	add r12, 8           ; |
	mov QWORD [rsp], r12 ; |> increment scoreboard cursor by u64 size

	jmp main_loop
	main_loop_end:

	mov r12, QWORD [rsp + 8] ; load scoreboard base pointer
	mov r13, QWORD [rsp]     ; load scoreboard cursor
	sub r13, r12             ; |
	shr r13, 3               ; |> len = (cursor - base)/elem_size

	mov rdi, r12
	mov rsi, r13
	call quicksort_u64

	mov rdi, part_1_colon
	call print
	mov rdi, QWORD [r12 + r13*8 - 8]
	call print_u64
	mov rdi, newline_part_2_colon
	call print
	mov rdi, QWORD [r12 + r13*8 - 8]
	add rdi, QWORD [r12 + r13*8 - 16]
	add rdi, QWORD [r12 + r13*8 - 24]
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

	failed_to_parse_number: db "Failed to parse number",0xA,0
	failed_to_map_memory:   db "Failed to map memory",0x0A,0
	part_1_colon:           db "Part 1: ",0
	newline_part_2_colon:   db 0x0A,"Part 2: ",0
	newline:                db 0x0A,0
section .bss
	scoreboard: resb 8
