section .text

strlen: ; u64 strlen(char* str)
	xor rax, rax

	; special case for empty string
	cmp rdi, 0
	je strlen_return

	strlen_loop:
	cmp BYTE [rdi + rax], 0
	je strlen_return
	inc rax
	jmp strlen_loop

	strlen_return:
	ret

error_and_exit: ; void error_and_exit(char* error_string)
	; rdi already holds error string
	call strlen

	mov rdx, rax      ; error_string length	
	mov rsi, rdi      ; error_string
	mov rdi, 2        ; stderr
	mov rax, 1        ; sys_write
	syscall

	mov rax, 60       ; sys_exit
	mov rdi, -1       ; exit code
	syscall

read_input_file:
	mov rax, 2         ; sys_open
                     ; filename, passed from caller in rdi
	mov rsi, 0         ; flags
	mov rdx, 0         ; mode
	syscall
	cmp rax, 0
	jl _start_failed_to_read_input_file

	mov r10, rax      ; save input file descriptor

	mov rax, 0        ; sys_read
	mov rdi, r10      ; input file descriptor
	mov rsi, input_file_buffer     
	mov rdx, QWORD [input_file_buffer_max_size]
	syscall
	cmp rax, 0
	jl _start_failed_to_read_input_file
	mov r11d, eax
	mov QWORD [input_file_buffer_size], r11

	mov rax, 3        ; sys_close
	mov rdi, r10      ; input file descriptor
	syscall

	jmp _start_input_file_read_successfully

	_start_failed_to_read_input_file:
	mov rax, 3        ; sys_close
	mov rdi, r10      ; input file descriptor
	syscall

	mov rdi, failed_to_read_input_file
	call error_and_exit

	_start_input_file_read_successfully:
	ret

section .data
	failed_to_read_input_file:  db "ERROR: Failed to read input file",0x0A,0
	input_file_buffer_max_size: dq 1024*1024*1024
section .bss
	input_file_buffer_size: resb 8   
	input_file_buffer:      resb 1024*1024*1024









section .text
	
	parse_u64: ; struct { int succeeded; u64 value; }  parse_u64(char* str, u64 len)
		xor rdx, rdx              ; local_value = 0
		xor r10, r10              ; i = 0
		parse_u64_loop:
		cmp r10, rsi              ; i < len
		jge parse_u64_succeeded

		movzx r11, BYTE [rdi + r10] ; str[i]
		sub r11, 0x30               ; digit = str[i] - '0'
		cmp r11, 10
		jae parse_u64_failed

		imul rdx, 10                ; local_value *= 10
		jb parse_u64_failed         ; fail on overflow
		
		add rdx, r11                ; local_value += digit
		jb parse_u64_failed         ; fail on overflow

		inc r10
		jmp parse_u64_loop

		parse_u64_succeeded:
		mov eax, 1
		; local_value is returned in rdx
		ret

		parse_u64_failed:
		mov eax, 0
		ret

	print_u64: ; void print_u64(u64 n)
		sub rsp, 32

		mov rax, rdi
		mov rdi, 10

		lea r10, [rsp + 32]
		print_u64_div_loop:
		mov rdx, 0
		div rdi
		dec r10
		add rdx, 0x30 ; '0'
		mov BYTE [r10], dl
		cmp rax, 0
		jne print_u64_div_loop

		mov rax, 1
		mov rdi, 1
		mov rsi, r10
		lea rdx, [rsp + 32]
		sub rdx, r10
		syscall

		add rsp, 32
		ret
