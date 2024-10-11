;Gabriel Jared e Pedro Pisseti
;nasm -f elf64 [LMpratica01]GabrielJared_PedroPisseti.asm && ld [LMpratica01]GabrielJared_PedroPisseti.o -o [LMpratica01]GabrielJared_PedroPisseti.x
;Executar: ./[LMpratica01]GabrielJared_PedroPisseti.x
;para verificar o resultado, o valor da n sequencia está sendo salvo em rbx

%define maxSize 4
%define maxSizePad 21
%define maxChars 20

section .data
    msgInserir    : db "Insira o valor para padovan: ", 0xA, 0 ; mensagem para o usuario inserir o valor da sequencia desejado
    msgInserirL   : equ $ - msgInserir
    
    msgErro       : db "Erro: entrada invalida!", 0xA, 0  ; mensagem de erro caso o valor não seja um numero ou seja menos q um caractere ou maior q dois
    msgErroL      : equ $ - msgErro
    
    nomeArquivo1  : db "p(", 0                           ;campos para o nome do arquivo
    nomeArquivo1l : equ $ - nomeArquivo1  
    nomeArquivo2  : db ").bin", 0
    nomeArquivo2l : equ $ - nomeArquivo2

section .bss 
    num               : resb maxSize               ; num - onde é armazenada a entrada do usuário
    resposta          : resb maxSizePad            ; resposta - onde é armazenado o resultado de fib(n), se n for válido
    descritor_arquivo : resd 1                     ; armazena o descritor do arquivo criado
    nomeArquivo       : resb maxChars              ; nomeArquivo - armazena o nome do arquivo criado
    p_n3: resb 4   ; Reservar espaço para P(n-3)
    p_n2: resb 4   ; Reservar espaço para P(n-2)
    p_n1: resb 4   ; Reservar espaço para P(n-1)
    p_n: resb 4    ; Reservar espaço para P(n)
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
    je verificar_apenas_enter
    
    ; Verifica se o caractere é numérico (entre '0' e '9')
    cmp byte [num + r8d], '0'        ; compara com '0'
    jl entrada_invalida              ; se menor q '0', rejeita
    cmp byte [num + r8d], '9'        ; compara com '9'
    jg entrada_invalida              ; se maior q '9', rejeita

    ; Se for um número entre '0' e '9', converte ASCII > decimal
    sub byte [num + r8d], 0x30       ; converte caractere ASCII para valor numérico

    inc r8d                          ; incrementa o índice de leitura
    jmp leitura                      ; volta para continuar lendo
verificar_apenas_enter:
    cmp r8d, 0                       ; Verifica se nenhum caractere foi lido antes do \n
    je entrada_invalida
validar_entrada:
    inc r8d                          ; r8d = num_digitos(num) + 1 
    cmp r8d, maxSize                 ; if (num_digitos(num) >= 3) mensagem de erro e encerramento;
    jge entrada_invalida
    cmp r8d, 2                       ; caso número seja de 2 digitos, parte direto para a conversão
    jg converte_int
    mov r9b, [num]                   ; senão, se num < 10, num ficará na forma 0n, tal q n é o valor de num
    mov byte [num+1], r9b
    mov byte [num], 0

converte_int:
    mov al, 10
    imul byte [num]
    add al, [num+1]
    movzx r12d, al                   ; usar movzx para mover byte para registrador 

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
    add r9b, 0x30                   ; converte de ASCII para int
    cmp r9b, 0x30
    je insereNum2
    mov [nomeArquivo + r10d], r9b
    inc r10d
insereNum2:
    mov r9b, [num + 1]
    add r9b, 0x30                   ; converte de ASCII para int
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

    ; Verificar se num == 0 || num == 1 || num == 2
    cmp byte r12b, 2
    jle padovan_base

    mov rcx, 1          ; p(n-3)
    mov rdx, 1          ; p(n-2)
    mov rsi, 1          ; p(n-1)
    mov rbx, 0          ; p(n)

    mov r8b, 3          ; i = 3
repete_padovan:
    cmp r8b, r12b        ; compara i com num
    jg escrever_arquivo  ; se i > num, sai do loop

    mov rbx, rdx        ; rbx (pn) = pn2
    add rbx, rcx        ; pn = pn2 + pn3

    mov rcx, rdx        ; pn3 = pn2
    mov rdx, rsi        ; pn2 = pn1
    mov rsi, rbx        ; pn1 = pn

    inc r8d             ; i++
    jmp repete_padovan  ; volta para o início do loop
    padovan_base:
        mov rbx, 1

escrever_arquivo:
    ;Escrita da resposta para ser inserida no arquivo
    mov [resposta], rbx

    mov rax, 1                      ; write com fd sendo o arquivo
    mov edi, [descritor_arquivo]    ; fd
    lea rsi, [resposta]             ; *buf
    mov rdx, maxSizePad             ; count
    syscall

    mov rax, 3                      ; fechar arquivo
    mov edi, [descritor_arquivo]
    syscall

    jmp fim
entrada_invalida:
    ; Escrever a mensagem de erro
    mov rax, 1                      ; Syscall write - Erro
    mov rdi, 1              
    lea rsi, [msgErro]    
    mov rdx, msgErroL     
    syscall
  
fim:
    mov rax, 60
    mov rdi, 0
    syscall