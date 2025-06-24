ORG 0x7C00  ; Endereço de memória onde a BIOS carrega o bootloader.

JMP main    ; Pula para o início do nosso código principal.

; Mensagem de saudação pré-estabelecida.
; O '0' no final (byte nulo) é usado para marcar o fim da string.
greeting_msg db 'Ola, ', 0

; Mensagem para pedir ao usuário que digite seu nome.
prompt_msg db 'Digite seu nome e tecle Enter: ', 0

; Caracteres de nova linha (Enter) para organizar a tela.
newline db 0x0D, 0x0A, 0  ; 0x0D = Carriage Return, 0x0A = Line Feed

; Área de memória (buffer) para armazenar o que o usuário digitar.
; 'resb 64' reserva 64 bytes de espaço.
USER_INPUT_BUFFER_SIZE equ 64
user_input_buffer resb USER_INPUT_BUFFER_SIZE

main:
    ; --- Configuração Inicial (Setup) ---
    ; Configura os segmentos de dados (DS e ES) para apontar para o mesmo
    ; local que o segmento de código (CS). Isso simplifica o acesso aos dados.
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; Configura a pilha (stack) para começar logo abaixo do nosso código.
    mov sp, 0x7C00

    ; --- Início da Lógica ---

    ; 1. Pede para o usuário digitar o nome.
    mov si, prompt_msg  ; Coloca o endereço da mensagem 'prompt_msg' em SI.
    call print_string   ; Chama nossa rotina para imprimir a string na tela.

    ; 2. Lê a entrada do teclado e armazena no buffer.
    mov di, user_input_buffer ; Coloca o endereço do buffer em DI.
    call read_string          ; Chama nossa rotina para ler do teclado.

    ; 3. Pula uma linha para a saída ficar mais organizada.
    mov si, newline
    call print_string

    ; 4. Imprime a saudação "Olá, ".
    mov si, greeting_msg      ; Aponta SI para a mensagem de saudação.
    call print_string         ; Imprime.

    ; 5. Imprime o nome que o usuário digitou.
    mov si, user_input_buffer ; Aponta SI para o que foi digitado.
    call print_string         ; Imprime.

    ; --- Finalização ---
    ; Trava o processador em um loop infinito, já que não há mais nada a fazer.
halt:
    jmp halt


; -----------------------------------------------------------------------------
; print_string: Imprime uma string na tela.
; Entrada: O registrador SI deve conter o endereço da string (terminada em 0).
; -----------------------------------------------------------------------------
print_string:
    mov ah, 0x0E        ; Função da BIOS para imprimir um caractere (Teletype).
.loop:
    lodsb               ; Carrega o byte de [DS:SI] em AL e incrementa SI.
    cmp al, 0           ; Compara o caractere com 0 (fim da string).
    je .done            ; Se for 0, pula para o final.
    int 0x10            ; Chama a interrupção da BIOS para imprimir o caractere em AL.
    jmp .loop           ; Volta para o início do loop para o próximo caractere.
.done:
    ret                 ; Retorna da função.


; -----------------------------------------------------------------------------
; read_string: Lê caracteres do teclado e armazena em um buffer.
; Entrada: O registrador DI deve conter o endereço do buffer.
; -----------------------------------------------------------------------------
read_string:
    mov cx, 0           ; Usaremos CX como um contador de caracteres.
.loop:
    mov ah, 0x00        ; Função da BIOS para esperar e ler uma tecla.
    int 0x16            ; Chama a interrupção da BIOS. O caractere ASCII fica em AL.

    ; Verifica se a tecla pressionada foi "Enter".
    cmp al, 0x0D        ; 0x0D é o código ASCII para a tecla Enter.
    je .done            ; Se for Enter, o usuário terminou de digitar.

    ; Verifica se o buffer está cheio.
    cmp cx, USER_INPUT_BUFFER_SIZE - 1
    je .loop            ; Se estiver cheio, ignora a tecla e espera por Enter.

    ; Se não foi Enter, ecoa o caractere na tela para o usuário ver.
    mov ah, 0x0E
    int 0x10

    ; Armazena o caractere no buffer.
    mov [di], al        ; Move o caractere de AL para o endereço em DI.
    inc di              ; Aponta DI para a próxima posição do buffer.
    inc cx              ; Incrementa o contador de caracteres.
    jmp .loop           ; Volta para o início para ler a próxima tecla.

.done:
    ; Adiciona o terminador nulo (0) no final do que foi digitado.
    ; Isso transforma a entrada do usuário em uma string válida para nossa
    ; função 'print_string'.
    mov byte [di], 0
    ret                 ; Retorna da função.


; O bootloader precisa ter 512 bytes no total e terminar com 0xAA55.
; Esta linha preenche o restante do espaço com zeros.
times 510 - ($ - $$) db 0

; Os dois últimos bytes devem ser a "palavra mágica" 0xAA55.
dw 0xAA55