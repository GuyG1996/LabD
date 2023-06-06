global x_struct

section .data
    format: db "%02hhx", 0  ; Format string for printing num elements
    format_get_multi: db "%01hhx", 0
    format_newline db "%c", 10, 0
    STATE: dd 0xAC10
    MASK: dd 0x012d 


    BUFFER_SIZE equ 600      ; Size of the buffer

x_struct: db 5
x_num: db 0xaa, 1,2,0x44,0x4f

y_struct: db 6
y_num: db 0xaa, 1,2,3,0x44,0x4f

section .bss
buffer resb BUFFER_SIZE            ; Buffer to store user input    

section .text
    extern printf
    extern malloc
    extern fgets
    extern stdin
    global main

main:
    push ebp                        ; Set up a new stack frame: save the previous base pointer onto the stack
    mov ebp, esp                    ; Move the current stack pointer (esp) to the base pointer (ebp)
    mov edi,1
    cmp edi, dword [ebp + 8]
    je print_default
    mov ecx, dword [ebp + 12]       ; Pointer to argv[1]
    mov ecx, [ecx+4]
    cmp word[ecx], "-I"
    je print_stdin
    cmp word [ecx], "-R"
    je print_rand
    jmp print_default

print_default:
    push format
    push dword x_struct             ; Save the struct pointer onto the stuck
    call print_multi
    add esp, 8
    push format
    push dword y_struct
    call print_multi
    add esp, 8
    push dword x_struct
    push dword y_struct
    call add_multi
    add esp, 8
    push format
    push dword eax
    call print_multi
    add esp, 8
    mov eax, 0
    mov esp, ebp
    pop ebp
    ret    

print_stdin:
    call get_multi 
    push dword eax
    call get_multi
    push dword eax
    call add_multi
    add esp, 8
    push format_get_multi
    push dword eax
    call print_multi
    add esp, 8
    mov eax, 0
    mov     esp, ebp
    pop     ebp
    ret 

print_rand:
    call PRMulti
    push format
    push dword eax
    call print_multi
    add esp,4
    mov esp, ebp
    pop ebp
    ret 



get_multi:
    push ebp                         ; Set up a new stack frame
    mov ebp, esp

    push dword [stdin] 
    push dword BUFFER_SIZE          
    push dword buffer             
    call fgets                      ; call fgets to get user input 
    add esp, 12                     ; Deallocate stack space used by 3 pushed arguments

    mov edx, buffer                ; Store the buffer pointer into edx 
    mov ebx, 0                     ; Initial counter
    
calculate_size:
    cmp byte [edx], 10         ; Check if we reached end of the buffer
    je save_into_struct           

    inc ebx                         ; add 1 to counter
    inc edx                         ; move edx to next argument
    jmp calculate_size              ; continue loop
    push ebx                        ; Save size in the stack

save_into_struct:
    inc ebx
    push dword ebx                       ; Save result struct size into stack
    call malloc                          ; Allocate memory for the result struct
    pop ebx                              ; Store size of struct in ebx (malloc changes it)

    mov edx, eax                         ; Store the pointer to the result struct in edx
    mov esi, buffer                      ; move buffer into esi
    dec ebx
    mov dword [edx], ebx                 ; Store the size into the struct

    push dword edx                       ; Store the pointer to the result array in stack
    mov edi, ebx                         ; Initial number of steps in the loop
    add edx, ebx                         ; edx points to the last argument in the array

save_args_loop:
    movzx eax, byte [esi]               ; Read a character from the input buffer
    cmp ebx, 0                          ; Check for end of string
    je exit_get_multi

    cmp al, '0'                         ; Compare with '0'
    jb exit_get_multi                   ; Jump if character is not a digit
    cmp al, '9'                         ; Compare with '9'
    ja hex_digit                        ; Jump if character is a hex digit

    ; Process decimal digit
    sub al, '0'                         ; Convert ASCII digit to value
    mov ah, 0                           ; Clear high byte
    jmp store_digit

hex_digit:
    cmp al, 'A'             ; Compare with 'A'
    jb exit_get_multi       ; Jump if character is not a hex digit
    cmp al, 'F'             ; Compare with 'F'
    jbe upper_case
    cmp al, 'a'             ; Compare with 'A'
    jb exit_get_multi       ; Jump if character is not a hex digit
    cmp al, 'f'             ; Compare with 'F'
    ja exit_get_multi       ; Jump if character 
    jbe lower_case

upper_case:                 ; Process hex digit upper case
    sub al, 'A'             ; Convert ASCII hex digit to value
    add al, 10              ; Add 10 to get the real value
    mov ah, 0               ; Clear high byte
    jmp store_digit

lower_case:                 ; Process hex digit upper case
    sub al, 'a'             ; Convert ASCII hex digit to value
    add al, 10              ; Add 10 to get the real value
    mov ah, 0               ; Clear high byte

store_digit:
    mov [edx], al                        ; Store the byte in the result array
    sub edx, 1                           ; edx now points to the next argument in the result array
    add esi, 1                           ; esi now points to the next argument in the input buffer
    dec edi                              ; decrease size by one
    cmp edi, 0
    jg save_args_loop                    ; if size equal or less then 0, end of the loop

exit_get_multi:                          ; Clean up the stack
    pop eax
    mov esp, ebp
    pop ebp
    ret

print_multi:
    push ebp                            ; Set up a new stack frame
    mov ebp, esp
    
    mov esi, [ebp + 8]                  ; Load struct pointer into esi   
    mov edi, [ebp + 12]                 ; Load format  
    movzx eax, byte [esi]               ; Size of array
    add esi, eax                        ; esi points to the last argument in the array

do_rep:
    cmp eax, 0                          ; if eax equal to 0, end of the loop
    jz loop_end

    movzx ebx, byte [esi]               ; move the current argument into ebx
    pushad                              ; save all registers into stuck 
    push dword ebx                      ; push the current argument into the stuck
    push dword edi                   ; push format into the stuck
    call printf                         ; print
    add esp, 8                          ; Deallocate stack space used by two pushed arguments
    popad                               ; Restore saved registers from stack

    dec eax                             ; decrease size
    dec esi                             ; pointer to the next byte in array

    jmp do_rep

loop_end:
    pushad                              ; save all registers onto the stack 
    push format_newline                 ; push the newline format onto the stack
    call printf                         ; print newline
    add esp, 4                          ; Deallocate stack space used by the pushed argument
    popad                               ; Restore saved registers from stack
    mov esp, ebp
    pop ebp
    ret 

get_max_min:
    push ebp                            ; Set up a new stack frame
    mov ebp, esp

    mov esi, [ebp + 8]                  ; Load first struct pointer into esi - y_struct
    movzx ecx, byte [esi]               ; Size of first - y_struct

    mov edi, [ebp + 12]                 ; Load second struct pointer into edi - x_struct

    movzx edx, byte [edi]               ; Size of second array - x_struct

    cmp ecx, edx                        ; Compare sizes
    jbe second_is_bigger                ; jumb if ebx (first struct size) is below or equal to second struct

first_is_bigger:
    mov eax, esi
    mov ebx, edi
    mov esi, ebx
    mov edi, eax
    jmp end

second_is_bigger:                       
    mov eax, edi
    mov ebx, esi

end:
    mov esp, ebp
    pop ebp
    ret 

addition_carry:
    sub al, 16
    mov ebx, 1
    jmp continue_addition_loop

addition_carry_left_arguments:
    sub al, 16
    mov ebx, 1
    jmp continue_add_left_arguments

not_equal_size: 
    push dword ecx
    mov ecx, 1
    cmp al, 15
    jg addition_carry
    jmp continue_addition_loop    

last_carry_equal_sizes:
    pop ecx                             ; ecx contain the diffrence between the sizes
    cmp ecx, 0
    jnz not_equal_size
    mov byte [edx], al                   ; Store the result byte in the result array
    jmp end_add_loop    

last_carry_left_arguments:
    mov byte[edx], al                      ; Store the result byte in the result array
    jmp end_add_loop

add_multi:
    push ebp                             ; Set up a new stack frame
    mov ebp, esp
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    push eax                             ; Save the x_struct pointer onto the stuck
    push ebx                             ; Save the y_struct pointer onto the stuck
    call get_max_min                     ; After this call, the struct with the bigger size will be in eax
    add esp, 8                           ; Deallocate stack space used by two pushed arguments 
    movzx ecx, byte [eax]                ; Size of bigger array - y_struct
    inc ecx                              ; Add 1 to size
    push dword ecx                       ; Save result struct size into stack
    call malloc                          ; Allocate memory for the result struct
    mov edx, eax                         ; Store the pointer to the result struct in edx
    pop eax                              ; Pop size of result struct
    movzx ecx, byte [ebx]                ; Size of smaller array - y_struct

    sub eax, 1                           ; The size of the array is the size of the struct - 1
    mov dword [edx], eax                 ; Store the size into the struct
    sub eax, ecx                         ; How much arguments there are more in the bigger array 
    push dword edx                       ; Store the pointer to the result array in stack
    push eax
    add edx, 1                           ; edx now points to the next argument in the result array 
    mov ebx,0                            ; initialize ebx in order to store the carry

addition_loop: 
    add esi, 1                           ; esi points to the current argument in the bigger array
    add edi, 1                           ; edi points to the current argument in the smaller array
    mov al, byte [esi]
    add eax, ebx                         ; Add carry
    mov ebx, 0
    add al, byte [edi]                   ; Perform the addition of the bytes with carry
    cmp ecx, 1                           ; check if last addition
    je last_carry_equal_sizes
    cmp al, 15                           ; chack if carry needed
    jg addition_carry
    continue_addition_loop:
        mov byte [edx], al               ; Store the result byte in the result array
        inc edx                          ; edx now points to the next argument in the result array 
        dec ecx                          ; decrease size by one
        cmp ecx, 0
        jnz addition_loop                ; if size equal 0, end of the loop
        pop ecx                          ; pop number of argument left in bigger array

add_left_arguments: 
    cmp ecx, 0
    jz end_add_loop
    add edi, 1
    mov al, byte [edi]               ; Save the argument in eax
    add eax, ebx
    mov ebx, 0
    cmp ecx, 1
    je last_carry_left_arguments
    cmp al, 15
    jg addition_carry_left_arguments
    continue_add_left_arguments:
        mov byte[edx], al                      ; Store the result byte in the result array
        inc edx                          ; edx now points to the next argument in the result array 
        dec ecx                             ; decrease size by one
        cmp ecx, 0
        jnz add_left_arguments              ; if size equal 0, end of the loop

end_add_loop:
    pop eax
    mov esp, ebp
    pop ebp
    ret  
    
PRMulti:
    push    ebp                 
    mov     ebp, esp  
    
    mov eax, dword [STATE]
    push eax                             ; Save size into stack
    call malloc                          ; Allocate memory for the struct
    mov edx, eax                         ; Store the pointer to the result struct in edx
    pop eax                              ; Pop size of result struct
    mov ecx, eax
    mov eax, edx
    mov dword [edx], ecx                 ; Store the pointer to the result array in stack
    push eax
    add edx, 1                           ; edx now points to the next argument in the result array
    CLC

    rand_loop:
        push ecx 
        call rand_num
        mov [edx], eax                       ; Store the result byte in the result array
        add edx, 1                           ; edx now points to the next argument in the result array 

        pop ecx
        sub ecx, 1
        jz rand_loop_end

        jmp rand_loop

    rand_loop_end:
        pop eax
        mov esp, ebp
        pop ebp
        ret

rand_num:
    push ebp
    mov ebp, esp
    mov ax, [STATE]
    mov bX, [MASK]

    xor bx, ax
    jp even_num
    
    STC ;cf = 1
    RCR ax,1
    jmp end_rand_num

    even_num:
        shr ax,1
        jmp end_rand_num

    end_rand_num:
        mov [STATE] ,ax
        movzx eax, byte[STATE]
        mov esp, ebp
        pop ebp
        ret  

