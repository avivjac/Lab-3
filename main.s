section .text
global main
extern strlen

main:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, [ebp+12] ; argv
    xor edi, edi      ; i = 0

.loop:
    cmp edi, [ebp+8] ; i < argc
    jge .call_encode

    ; Check for -i
    mov eax, [esi + edi*4]
    cmp word [eax], '-i'
    je .open_input
    cmp word [eax], 0x692D ; '-i' in little endian? '-'=0x2D, 'i'=0x69 -> 0x692D. 
                          ; Wait, `cmp word [eax]` checks 2 bytes. '-i' string is 0x2D, 0x69. 
                          ; Little endian: low byte at low addr. [eax]=0x2D, [eax+1]=0x69. 
                          ; So word is 0x692D.

    ; Let's be safer and check bytes
    cmp byte [eax], '-'
    jne .check_outfile
    cmp byte [eax+1], 'i'                         ; -i/-o need space ?????
    je .open_input
    
.check_outfile:
    cmp byte [eax], '-'
    jne .print_arg
    cmp byte [eax+1], 'o'
    je .open_output
    jne .print_arg

.open_input:
    ; open(argv[i]+2, O_RDONLY)
    mov ebx, eax
    add ebx, 2          ; filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; O_RDONLY
    int 0x80
    
    mov [Infile], eax
    jmp .print_arg      ; Proceed to print arg (debug)

.open_output:
    ; open(argv[i]+2, O_WRONLY | O_CREAT | O_TRUNC, 0644)
    mov ebx, eax
    add ebx, 2          ; filename
    mov eax, 5          ; sys_open
    mov ecx, 65         ; O_WRONLY(1) | O_CREAT(64) | O_TRUNC(512)? 
                         ; O_WRONLY=1, O_CREAT=64, O_TRUNC=512 (0x200)?
                         ; Let's verify Linux standard flags. 
                         ; O_RDONLY=0, O_WRONLY=1, O_RDWR=2
                         ; O_CREAT=0100 (64)
                         ; O_TRUNC=01000 (512)
                         ; So 1 | 64 | 512 = 577? 
                         ; Wait, strict posix might vary but strictly Linux x86:
                         ; O_WRONLY = 01
                         ; O_CREAT = 0100 (octal) -> 64 decimal
                         ; O_TRUNC = 01000 (octal) -> 512 decimal
                         ; 1 + 64 + 512 = 577.
    mov ecx, 0x241      ; 577 in hex: 200 + 40 + 1 = 241
    mov edx, 0644o      ; mode
    int 0x80
    
    mov [Outfile], eax
    jmp .print_arg

.print_arg:
    ; Calculate strlen(argv[i])
    mov eax, [esi + edi*4] ; argv[i]
    push eax
    call strlen
    add esp, 4
    ; EAX now has length

    ; Print argv[i]
    mov edx, eax           ; length
    mov ecx, [esi + edi*4] ; buffer = argv[i]
    mov ebx, 1             ; stdout (always print debug usage to stdout? Or stderr? Lab says "all command line arguments are printed to stderr" in 1.A instructions. User request 1.A said "stdout". User request 1.A text: "debug is always on, so all command line arguments are printed to stderr... Write a function main... that prints all command line arguments to stdout". This is contradictory. 
    ; "Recall... acts like debug printout... printed to stderr. Write a function... that prints... to stdout". 
    ; I will stick to stdout as per the explicit "prints... to stdout" instruction.
    mov eax, 4             ; sys_write
    int 0x80

    ; Print newline
    mov edx, 1             ; length
    mov ecx, newline       ; buffer
    mov ebx, 1             ; stdout
    mov eax, 4             ; sys_write
    int 0x80

    inc edi
    jmp .loop

.call_encode:
    call encode

.end:
    xor eax, eax ; return 0
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

encode:
    push ebp
    mov ebp, esp
    
.encode_loop:
    ; Read 1 byte from Infile
    mov eax, 3          ; sys_read
    mov ebx, [Infile]   ; file descriptor
    mov ecx, buffer     ; buffer addr
    mov edx, 1          ; count
    int 0x80

    cmp eax, 0          ; Check if EOF (0) or error (<0)
    jle .encode_end

    ; Process the byte
    mov al, [buffer]
    cmp al, 'A'
    jl .write_byte
    cmp al, 'Z'
    jg .write_byte
    
    ; Add 3
    add al, 3
    mov [buffer], al

.write_byte:
    ; Write 1 byte to Outfile
    mov eax, 4          ; sys_write
    mov ebx, [Outfile]  ; file descriptor
    mov ecx, buffer     ; buffer addr
    mov edx, 1          ; count
    int 0x80
    
    jmp .encode_loop

.encode_end:
    mov esp, ebp
    pop ebp
    ret

section .data
    newline db 10
    Infile dd 0     ; STDIN
    Outfile dd 1    ; STDOUT

section .bss
    buffer resb 1
