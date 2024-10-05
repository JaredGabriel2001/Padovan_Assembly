;Gabriel Jared e Pedro Pisseti
;nasm -f elf64 padovan.asm && ld padovan.o -o padovan.x

%define maxSize 4
%define maxSizePad 21
%define maxChars 20

section .data
    msgInserir    : db "Insira o valor para padovan: ", 0xA,0 
    msgInserirL   : equ $ - msgInserir
    
    msgErro       : db "Erro: entrada invalida!", 0xA,0  
    msgErroL      : equ $ - msgErro
    
    nomeArquivo1  : db "p(",0
    nomeArquivo1l: equ $ - nomeArquivo1  
    nomeArquivo2  : db ").bin", 0
    nomeArquivo2l: equ $ - nomeArquivo2

section .bss 
    num: resb maxSize               ;num - onde é armazenada a entrada do usuário
    resposta: resb maxSizePad       ;resposta - onde é armazenado o resultado de fib(n), se n for válido
    descritor_arquivo: resd 1       ;armazena o descritor do arquivo criado
    nomeArquivo: resb maxChars      ;nomeArquivo - armazena o nome do arquivo criado

section .text
    global _start

_start:
    mov rax, 1                      ;Syscall write - Inserir Padovan
    mov rdi, 1              
    lea rsi, [msgInserir]    
    mov edx, msgInserirL     
    syscall

    mov r8d, 0
leitura:
    mov rax, 0                       ;leitura
    mov rdi, 0
    lea rsi, [num + r8d]
    mov edx, 1                       ;leitura byte a byte
    syscall

    cmp byte [num + r8d], 10         ;caso caracter lido seja quebra de linha, avança para a parte de verificação
    je validar_entrada
    
    sub byte [num + r8d], 0x30       ;senão, converte ASCII > decimal, incrementa r8d e lê próximo byte
    inc r8d
    jmp leitura

validar_entrada:
    inc r8d                          ;r8d = num_digitos(num) + 1 
    cmp r8d, maxSize                 ;if (num_digitos(num) >= 3) mensagem de erro e encerramento;
    jge entrada_invalida
    cmp r8d, 2                       ;caso número seja de 2 digitos, parte direto para a conversão
    jg converte_int
    mov r9b, [num]                   ;senão, se num < 10, num ficará na forma 0n, tal que n é o valor de num
    mov byte [num+1], r9b
    mov byte [num], 0

converte_int:
    mov al, 10
    imul byte [num]
    add al, [num+1]
    mov r12b, al
    
    cmp byte r12b, 0                   ;r12b terá armazenado num na forma decimal
    je entrada_invalida                ;caso r12b = 0, mensagem de erro e encerramento


    ;entrada é limitada até 93
    ;registrador de 64 bits não consegue representar corretamente valores maiores que 93
    ;se r12 > 93, mensagem de erro e encerramento
    cmp byte r12b, 93
    jg entrada_invalida
    ;se o número não é inválido, executa a nomeação do arquivo

nomear_arquivo:
    mov r9d, 0
    ;r10 - tamanho de fileName
    mov r10d, 0
    ;inserção de nomeArquivo em fileName

inserir_primeira_parte:             ;criação de arquivo com dois digitos, insere o proprio num diretamente
    cmp byte [nomeArquivo1 + r9d], 0
    je insereNum
    mov r11b, [nomeArquivo1 + r9d]
    mov [nomeArquivo + r10d], r11b
    inc r10d
    inc r9d
    jmp inserir_primeira_parte
insereNum:
    ;mov r10b, 4
    mov r9b, [num]
    ;converte para ASCII
    add r9b, 0x30
    ;se r9b = '0', pula pra inserção do 2° número
    cmp r9b, 0x30
    je insereNum2
    ;senão, insere o 1° número
    mov [nomeArquivo + r10d], r9b
    inc r10d
    ;inserção do 2° digito
insereNum2:
    mov r9b, [num + 1]
    ;converte para ASCII
    add r9b, 0x30
    mov [nomeArquivo + r10d], r9b
    inc r10d

    mov r9d, 0

inserir_segunda_parte:
    ;quando termina de inserir, vai para o laço
    cmp r9d, nomeArquivo2l
    jg laco
    mov r11b, [nomeArquivo2 + r9d]
    mov [nomeArquivo + r10d], r11b
    inc r10d
    inc r9d
    jmp inserir_segunda_parte

laco:

    mov rax, 2                      ; open file
    lea rdi, [nomeArquivo]          ; *pathname
    mov rsi, 0x241             
    mov rdx, 0644 
    syscall

    mov [descritor_arquivo], eax    ;armazena o fd do arquivo em fileHandle

    mov rbx, 1   ; P(n-3)
    mov rcx, 1   ; P(n-2)
    mov rdx, 1   ; P(n-1)
    mov rsi, [num]   ; contador

repete_padovan:
    sub rsi, 1
    mov rax, rbx  ; salva P(n-3) em rax
    add rbx, rcx  ; P(n-3) + P(n-2)
    mov rcx, rdx  ; P(n-2) vira P(n-1)
    mov rdx, rax  ; P(n-3) vira P(n-2)
    cmp rsi, 2
    jg repete_padovan
    
padovan_base:
    mov rbx, 1                     ; Padovan(0) = Padovan(1) = Padovan(2) = 1
    jmp finalizar_padovan

finalizar_padovan:
    ret                            ; O resultado está em rbx
    
escrever_arquivo:
    mov [resposta], rbx

    mov rax, 1                     ;write com fd sendo o arquivo
    mov edi, [descritor_arquivo]   ;fd
    lea rsi, [resposta]            ; *buf
    mov edx, maxSizePad            ; count
    syscall

    mov rax, 3                     ; fechar arquivo
    mov edi, [descritor_arquivo]
    syscall

    jmp fim

entrada_invalida:
    mov rax, 1                     ;codigo write
    mov rdi, 1                     ;write on terminal
    mov rsi, [msgErro]             ;a mensagem de entrada
    mov edx, msgErroL              ;apenas os chars necessarios
    syscall

fim:
    mov rax, 60
    mov rdi, 0
    syscall