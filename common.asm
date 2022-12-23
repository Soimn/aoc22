section .text

; NOTE: All the eat_* return eaten length as 32bit, I don't expect these to be used on > 4GB files

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

print: ; void print(char* str)
	sub rsp, 0x10
	mov QWORD [rsp], rdi
	call strlen
	mov rdi, QWORD [rsp]
	add rsp, 0x10

	mov rdx, rax      ; str length
	mov rsi, rdi      ; str
	mov rdi, 1        ; stdout
	mov rax, 1        ; sys_write
	syscall

	ret

print_w_len: ; rdi - str, rsi - len
	mov rdx, rsi      ; str length
	mov rsi, rdi      ; str
	mov rdi, 1        ; stdout
	mov rax, 1        ; sys_write
	syscall

	ret

error_and_exit: ; void error_and_exit(char* error_string)
	sub rsp, 0x10
	mov QWORD [rsp], rdi
	call strlen
	mov rdi, QWORD [rsp]
	add rsp, 0x10

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
	
parse_u64: ; struct { int succeeded; u64 value; }  parse_u64(char* str, i64 len)
	xor rdx, rdx              ; local_value = 0
	xor r10, r10              ; i = 0
	parse_u64_loop:
	cmp r10, rsi              ; i < len
	jge parse_u64_succeeded

	movzx r11, BYTE [rdi + r10] ; str[i]
	sub r11, 0x30               ; digit = str[i] - '0'
	cmp r11, 10
	jae parse_u64_failed

	imul rdx, rdx, 10           ; local_value *= 10
	jb parse_u64_failed         ; fail on overflow, imul sets carry flag which jb jumps on
	
	add rdx, r11                ; local_value += digit
	jb parse_u64_failed         ; fail on overflow, unsigned so jump on carry instead of the overflow flag

	inc r10
	jmp parse_u64_loop

	parse_u64_succeeded:
	mov eax, 1
	; local_value is returned in rdx
	ret

	parse_u64_failed:
	mov eax, 0
	ret

; -1 is passed as value_len on failing to parse the number (overflow)
eat_u64: ; struct { i64 value_len; u64 value; }  eat_u64(char* str, i64 len)
	xor rdx, rdx                ; local_value = 0
	xor r10, r10                ; i = 0
	eat_u64_loop:
	cmp r10, rsi                ; i < len
	jge eat_u64_succeeded

	movzx r11, BYTE [rdi + r10] ; str[i]
	sub r11, 0x30               ; digit = str[i] - '0'
	cmp r11, 10
	jae eat_u64_succeeded

	imul rdx, rdx, 10           ; local_value *= 10
	jb eat_u64_failed           ; fail on overflow, imul sets carry flag which jb jumps on
	
	add rdx, r11                ; local_value += digit
	jb eat_u64_failed           ; fail on overflow, unsigned so jump on carry instead of the overflow flag

	inc r10
	jmp eat_u64_loop

	eat_u64_succeeded:
	mov eax, r10d
	; local_value is returned in rdx
	ret

	eat_u64_failed:
	mov eax, -1
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

quicksort_u64: ; void quicksort(u64* arr, u64 len)
	cmp rsi, 1                       ; if (len <= 1) return;
	ja partition
	ret
	partition:
	mov r10, QWORD [rdi + rsi*8 - 8] ; pivot = arr[len - 1]
	mov rdx, 0                       ; i = 0
	mov rcx, 0                       ; j = 0
	partition_loop:
	cmp rdx, rsi                     ; for (; i < len; ++i)
	jge partition_loop_end
	mov r11, QWORD [rdi + rdx*8]     ; current = arr[i]
	cmp r11, r10                     ; if (current <= pivot)
	ja partition_loop_step
	mov r8, QWORD [rdi + rcx*8]      ; tmp = arr[j]
	mov QWORD [rdi + rcx*8], r11     ; arr[j] = current
	mov QWORD [rdi + rdx*8], r8      ; arr[i] = tmp
	inc rcx                          ; j += 1
	partition_loop_step:
	inc rdx
	jmp partition_loop
	partition_loop_end:
	sub rsp, 0x20
	mov QWORD [rsp + 24], rdi
	mov QWORD [rsp + 16], rsi
	mov QWORD [rsp +  8], rcx
	mov rdi, rdi                     ; arr = &arr[0]
	lea rsi, [rcx - 1]               ; len = j - 1
	call quicksort_u64
	mov rdi, QWORD [rsp + 24]
	mov rsi, QWORD [rsp + 16]
	mov rcx, QWORD [rsp +  8]
	lea rdi, QWORD [rdi + rcx*8]     ; arr = &arr[j]
	sub rsi, rcx                     ; len = len - j
	call quicksort_u64
	add rsp, 0x20
	ret

eat_whitespace: ; struct { u64 eat_len; } eat_whitespace(char* str, i64 len)
	xor r10, r10
	eat_whitespace_loop:
	cmp r10, rsi
	jge eat_whitespace_loop_end

	movzx r11, BYTE [rdi + r10]
	sub r11, 9
	cmp r11, 5
	setb r8b
	cmp r11, 0x17
	sete r9b
	or r8b, r9b
	cmp r8b, 1
	jne eat_whitespace_loop_end
	inc r10
	jmp eat_whitespace_loop
	eat_whitespace_loop_end:

	mov eax, r10d
	ret

eat_whitespace_until_newline: ; struct { u64 eat_len; } eat_whitespace(char* str, i64 len)
	xor r10, r10
	eat_whitespace_until_newline_loop:
	cmp r10, rsi
	jge eat_whitespace_until_newline_loop_end

	movzx r11, BYTE [rdi + r10]
	sub r11, 9
	cmp r11, 5
	setb r8b
	cmp r11, 0x17
	sete r9b
	or r8b, r9b
	cmp r11, 1
	setne r9b
	and r8b, r9b
	cmp r8b, 1
	jne eat_whitespace_until_newline_loop_end
	inc r10
	jmp eat_whitespace_until_newline_loop
	eat_whitespace_until_newline_loop_end:

	mov eax, r10d
	ret

eat_until_newline: ; rdi - str, rsi - len -> eax eaten_len
	xor r10, r10
	eat_until_newline_loop:
	cmp r10, rsi
	jge eat_until_newline_loop_end
	movzx r11, BYTE [rdi + r10]
	cmp r11, 0xA
	je eat_until_newline_loop_end
	inc r10
	jmp eat_until_newline_loop
	eat_until_newline_loop_end:

	mov eax, r10d
	ret

is_alpha:
	mov r10, rdi
	and rdi, 0x1F
	dec rdi
	cmp rdi, 0x1A
	setb dl
	shr r10, 6
	add r10b, dl
	cmp r10b, 2
	sete r10b
	movzx rax, r10b
	ret

is_digit:
	sub rdi, 0x30
	cmp rdi, 0xA
	setb al
	movzx rax, al
	ret

zero: ; rdi - ptr, rsi - size
	xor r10, r10
	zero_loop:
	cmp r10, rsi
	jge zero_loop_end
	mov BYTE [rdi + r10], 0
	inc r10
	jmp zero_loop
	zero_loop_end:
	ret

copy: ; rdi - src, rsi - dst, rcx - len
	lea r10, [rdi + rcx]
	copy_loop:
	cmp rdi, r10
	jge copy_loop_end
	mov r11b, BYTE [rdi]
	mov BYTE [rsi], r11b
	inc rdi
	inc rsi
	jmp copy_loop
	copy_loop_end:
	ret
