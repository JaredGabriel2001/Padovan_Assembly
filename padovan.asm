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
    resultado dd 0           ; Reserva 1 byte para armazenar o resultado

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

    mov r9d, 0
leitura:
    mov rax, 0                       ; leitura
    mov rdi, 0                       ; stdin
    lea rsi, [num + r9d]
    mov rdx, 4                       ; leitura byte a byte
    syscall

    cmp byte [num + 1], 10         ; caso o segundo caracter for um ENTER
    je validar_entrada1

    cmp byte [num + 2], 10        ; caso o terceiro caracter for um ENTER
    je validar_entrada2

    jmp entrada_invalida                      ; Se não for nenhum dos dois é erro

validar_entrada1:
    mov al, byte [num]
    sub al, '0'
    mov [resultado], rax       ; Armazena o resultado final
    jmp nomear_arquivo

validar_entrada2:
    mov al, byte [num]        ; Carrega o primeiro byte (dígito) em AL
    sub al, '0'               ; Converte de ASCII para valor numérico (0-9)
    mov bl, 10                ; Carrega o valor 10 em BL
    mul bl                    ; Multiplica AL por BL.
    mov bl, byte [num+1]      ; Carrega o segundo dígito ASCII em BL
    sub bl, '0'               ; Converte de ASCII para valor numérico (0-9)
    add al, bl                ; Soma o segundo dígito ao resultado
    mov [resultado], rax       ; Armazena o resultado final
    jmp nomear_arquivo         ; Salta para a rotina de nomear arquivo

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
    mov r9b, byte al
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

    mov rsi, [resultado]                   ; usar o registrador de 32 bits para contador
    
    ; Verificar se n é menor que 3
    cmp ecx, 3
    jl finalizar_padovan                 ; Para n < 3
    ; FAZER ALGUM TRATAMENTO PARA A SAIDA SER 1 caso isso seja verdadeiro

    mov r10, 1                      ; P(n-3)
    mov r11, 1                      ; P(n-2)
    mov r12, 1                      ; P(n-1)

repete_padovan:
    sub rsi, 1

    ; Calcular P(n) = P(n-2) + P(n-3)
    mov rax, r11                    ; P(n-2)
    add rax, r10                    ; P(n) = P(n-2) + P(n-3)

    ; Atualizar os registradores para a próxima iteração
    mov r10, r11                    ; P(n-3) = P(n-2)
    mov r11, r12                    ; P(n-2) = P(n-1)
    mov r12, rax                    ; P(n-1) = P(n)
    cmp rsi, 2
    jg repete_padovan


finalizar_padovan:
    ; Aqui faremos a escrita da resposta antes de retornar
    mov [resposta], rax

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
    mov rax, 1                      ; codigo write
    mov rdi, 1                      ; write on terminal
    lea rsi, [msgErro]              ; a mensagem de entrada
    mov rdx, msgErroL               ; apenas os chars necessarios
    syscall

fim:
    mov rax, 60
    mov rdi, 0
    syscall
