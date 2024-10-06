;Gabriel Jared e Pedro Pisseti
;nasm -f elf64 padovan.asm && ld padovan.o -o padovan.x

%define maxSize 4
%define maxSizePad 21
%define maxChars 20

section .data
    msgInserir    : db "Insira o valor para padovan: ", 0xA, 0 
    msgInserirL   : equ $ - msgInserir
    
    msgErro       : db "Erro: entrada invalida!", 0xA, 0  
    msgErroL      : equ $ - msgErro
    
    nomeArquivo1  : db "p(", 0
    nomeArquivo1l : equ $ - nomeArquivo1  
    nomeArquivo2  : db ").bin", 0
    nomeArquivo2l : equ $ - nomeArquivo2

section .bss 
    num: resb maxSize               ; num - onde é armazenada a entrada do usuário
    resposta: resb maxSizePad       ; resposta - onde é armazenado o resultado de fib(n), se n for válido
    descritor_arquivo: resd 1       ; armazena o descritor do arquivo criado
    nomeArquivo: resb maxChars      ; nomeArquivo - armazena o nome do arquivo criado

section .text
    global _start

_start:
    mov rax, 1                      ; Syscall write - Inserir Padovan
    mov rdi, 1              
    lea rsi, [msgInserir]    
    mov rdx, msgInserirL     
    syscall

    mov r8d, 0
leitura:
    mov rax, 0                       ; leitura
    mov rdi, 0                       ; stdin
    lea rsi, [num + r8d]
    mov rdx, 1                       ; leitura byte a byte
    syscall

    cmp byte [num + r8d], 10         ; caso caracter lido seja quebra de linha, avança para a parte de verificação
    je validar_entrada
    
    sub byte [num + r8d], 0x30       ; senão, converte ASCII > decimal, incrementa r8d e lê próximo byte
    inc r8d
    jmp leitura

validar_entrada:
    inc r8d                          ; r8d = num_digitos(num) + 1 
    cmp r8d, maxSize                 ; if (num_digitos(num) >= 3) mensagem de erro e encerramento;
    jge entrada_invalida
    cmp r8d, 2                       ; caso número seja de 2 digitos, parte direto para a conversão
    jg converte_int
    mov r9b, [num]                   ; senão, se num < 10, num ficará na forma 0n, tal que n é o valor de num
    mov byte [num+1], r9b
    mov byte [num], 0

converte_int:
    mov al, 10
    imul byte [num]
    add al, [num+1]
    movzx r12d, al                   ; usar movzx para mover byte para registrador de 32 bits
    
    cmp r12d, 0                      ; r12d terá armazenado num na forma decimal
    je entrada_invalida              ; caso r12d = 0, mensagem de erro e encerramento

    ; cmp r12d, 93                     ; se r12d > 93, mensagem de erro e encerramento
    ; jg entrada_invalida

nomear_arquivo:
    xor r9d, r9d
    xor r10d, r10d

inserir_primeira_parte:
    cmp byte [nomeArquivo1 + r9d], 0
    je insereNum
    mov r11b, [nomeArquivo1 + r9d]
    mov [nomeArquivo + r10d], r11b
    inc r10d
    inc r9d
    jmp inserir_primeira_parte
insereNum:
    mov r9b, [num]
    add r9b, 0x30                   ; converte para ASCII
    cmp r9b, 0x30
    je insereNum2
    mov [nomeArquivo + r10d], r9b
    inc r10d
insereNum2:
    mov r9b, [num + 1]
    add r9b, 0x30                   ; converte para ASCII
    mov [nomeArquivo + r10d], r9b
    inc r10d

    xor r9d, r9d

inserir_segunda_parte:
    cmp r9d, nomeArquivo2l
    jge calc_padovan
    mov r11b, [nomeArquivo2 + r9d]
    mov [nomeArquivo + r10d], r11b
    inc r10d
    inc r9d
    jmp inserir_segunda_parte

calc_padovan:
    mov rax, 2                      ; open file
    lea rdi, [nomeArquivo]          ; *pathname
    mov rsi, 0x241                  ; flags
    mov rdx, 0644                   ; mode
    syscall

    mov [descritor_arquivo], eax    ; armazena o fd do arquivo em fileHandle

    mov rbx, 1                      ; P(n-3)
    mov rcx, 1                      ; P(n-2)
    mov rdx, 1                      ; P(n-1)
    mov esi, r12d                   ; usar o registrador de 32 bits para contador

repete_padovan:
    sub esi, 1
    mov rax, rbx                    ; salva P(n-3) em rax
    add rbx, rcx                    ; P(n-3) + P(n-2)
    mov rcx, rdx                    ; P(n-2) vira P(n-1)
    mov rdx, rax                    ; P(n-3) vira P(n-2)
    cmp esi, 2
    jg repete_padovan
padovan_base:
    mov rbx, 1                      ; Padovan(0) = Padovan(1) = Padovan(2) = 1
    jmp finalizar_padovan

finalizar_padovan:
    ; Aqui faremos a escrita da resposta antes de retornar
    mov [resposta], rbx

    mov rax, 1                      ; write com fd sendo o arquivo
    mov edi, [descritor_arquivo]    ; fd
    lea rsi, [resposta]             ; *buf
    mov rdx, maxSizePad             ; count
    syscall

    mov rax, 3                      ; fechar arquivo
    mov edi, [descritor_arquivo]
    syscall

    ; Ajustar ret para encerrar corretamente
    mov rax, 60
    mov rdi, 0
    syscall

    jmp fim
entrada_invalida:
    mov rax, 1                      ; codigo write
    mov rdi, 1                      ; write on terminal
    lea rsi, [msgErro]              ; a mensagem de entrada
    mov rdx, msgErroL               ; apenas os chars necessarios
    syscall

fim:
    mov rax, 60
    mov rdi, 0
    syscall