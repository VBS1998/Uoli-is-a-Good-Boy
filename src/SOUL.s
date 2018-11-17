@ Este arquivo é segmentado 4 partes (questão de legibilidade)
@   * Seção para declaração de contantes    : Onde as contantes são declaradas
@   * Seção do vetor de interrupções        : Código referente ao vetor de interrupções
@   * Seção de texto                        : Onde as rotinas são escritas
@   * Seção de dados                        : Onde são adicionadas as variáveis (.word, .skip) utilizadas neste arquivo


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      Seção de Constantes/Defines           @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ Constantes para os Modos de operação do Processador, utilizados para trocar entre modos de operação (5 bits menos significativos)
    .set MODE_USER,                 0x10
    @ Você pode definir as outras....
@    .set MODE_IRQ,                  0xxx
@    .set MODE_SUPERVISOR,           0xxx
@    .set MODE_SYSTEM,               0xxx

@ Constantes referentes aos endereços
	.set USER_ADDRESS,				0x77812000      @ Endereço do código de usuário
	.set STACK_POINTER_IRQ,			0x7E000000      @ Endereço inicial da pilha do modo IRQ
	.set STACK_POINTER_SUPERVISOR,	0x7F000000      @ Endereço inicial da pilha do modo Supervisor
	.set STACK_POINTER_USER, 		0x80000000      @ Endereço inicial da pilha do modo Usuário

@ Constantes Referentes ao TZIC
    .set TZIC_BASE,                 0x0FFFC000
    .set TZIC_INTCTRL,              0x00
    .set TZIC_INTSEC1,              0x84
    .set TZIC_ENSET1,               0x104
    .set TZIC_PRIOMASK,             0x0C
    .set TZIC_PRIORITY9,            0x424


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      Seção do Vetor de Interrupções        @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Este vetor possui entradas das rotinas para o tratamento de cada tipo de interrupção
.org 0x0                    @ 0x0 --> salto para rotina de tratamento do RESET
.section .iv,"a"
_start:
interrupt_vector:
	b reset_handler        @ Rotina utilizada para interrupção RESET

.org 0x08                  @ 0x8 --> salto para rotina de tratamento de syscalls (interrupções svc)
	b svc_handler          @ Rotina utilizada para interrupção SVC

.org 0x18                  @ 0x18 --> salto para rotina de tratamento de interrupções do tipo IRQ
	b irq_handler          @ Rotina utilizada para interrupção IRQ (GPT, ...)



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      Seção de Texto                        @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.org 0x100
.text

@ Rotina de tratamento da interrupção RESET.
@ Esta rotina é unicamente invocada assim que o processador é iniciado (interrupção reset). O processador é iniciado no modo de operação de sistema, com as flags zeradas e as INTERRUPÇÕES DESABILITADAS!
@ Esta rotina é utilizada para configurar todo o sistema, antes de executar o código de usuário (ronda, segue-parede), que esta localizado em USER_ADDRESS.
@ Uma vez que o código de usuário é executado, syscalls são utilizadas para voltar aos modo de operação de sistema.
@
@ Essa rotina deve configurar:
@   1)  Inicializar o contador de tempo (variável conta
    @Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
    ldr r0, =interrupt_vector @ carrega vetor de interrupcoedor) e o endereço base do vetor de interrupções no coprocessador p15    -- (OK)
@
@   2)  Inicializar as pilhas dos modos de operação
@          * Alterar o registrador sp, dos modos IRQ e SVC (cada modo tem seus próprios registradores!), com endereços definidos. Assim, sempre que chavearmos de modo, este tera um endereço para sua pilha, separadamente.
@          * Lembre-se que, o registrador CPRS (que pode ser acessado por instruções mrs/msr) contém o modo de operação atual do processador. Para trocar de modo, basta escrever os bits referentes ao novo modo, no CPRS. Apenas o modo de operação USER possui restrições quanto a escrever no CPRS. Para retornar a um modo de operação de sistema, o usuário deve realizar uma syscall (que é tratada pelo svc_handler)
@
@   3)  Configurar os dispositivos:
@          * Configurar o GPT para gerar uma interrupção do tipo IRQ (que será tratada por irq_handler) assim que o contador atingir um valor definido. O GPT é um contador de propósito geral e deve-se configurar a frequencia e o valor que será contado. Cada interrupção gerada deste contador representa uma unidade de tempo do seu sistema (quanto mais alto ou baixo o valor de contagem, seu tempo passará mais rapído ou devagar)
@          * Configurar GPIO: Definir em GDIR quais portas do GPIO são de entrada e saída.
@
@   4)  Configurar o TZIC (Controlador de Interrupções)         -- (OK)
@          * Após configurar as interrupções dos dispositivos, a configuração do TZIC deve ser realizada para permitir que as interrupções dos periféricos cheguem a CPU.
@          * Nesta parte, estamos cadastrando as interrupcões do GPT como habilitadas para o TZIC
@
@   5)  Habilitar interrupções e executar o código do usuário
@           * Uma vez que o sistema foi configurado, devemos executar (saltar para) o código do usuário (segue-parede/ronda), que esta localizado em USER_ADDRESS
@           * Lembre-se também de habilitar as interrupções antes de executar o código usuário. Para habilitar as interrupções escreva nos bits do CPRS (bit de IRQ e FIQ. Feito isso, as interrupções cadastradas no TZIC irão interromper o processador, que irá parar o que estiver fazendo, chavear de modo e executar a rotina de tratamento adequada para cada interrupção.
@           * Uma vez que o código de usuário é executado, a rotina reset_handler não é mais usada (até reinicar). Apenas as rotinas irq_handler (para interrupções do GPT) e svc_handler (para syscalls feitas pelo usuário) são utilizadas.

reset_handler:
@   1) ----------- Inicialização do contador e do IV -------------------------
    @ zera contador de tempo
    mov r0, #0
    ldr r1, =counter
    str r0, [r1]

    @Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
    ldr r0, =interrupt_vector @ carrega vetor de interrupcoes
    mcr p15, 0, r0, c12, c0, 0 @ no co-processador 15

@   2) ----------- Inicialização das pilhas modos de operação  ---------------
    @ Você pode inicializar as pilhas aqui (ou, pelo menos, antes de executar o código do usuário)


    msr  CPSR_c,  #0b11010010           @ IRQ mode, IRQ/FIQ disabled
    ldr r13, =inicio_pilha
    msr  CPSR_c,  #0b11010011           @ SUPERVISOR mode, IRQ/FIQ disabled


@    3) ----------- Configuração dos periféricos (GPT/GPIO) -------------------
    @ Você pode configurar os periféricos aqui....

    @Escrever 0x41 no GPT_CR
    ldr r0, =0x53FA0000
    mov r1, #0x41
    str r1, [r0]

    @Zerar o prescaler
    ldr r0, =0x53FA0004
    mov r1, #0x0
    str r1, [r0]

    @200 no ocr1
    ldr r0, =0x53FA0010
    mov r1, #100
    str r1, [r0]

    @1 no IR
    ldr r0, =0x53FA000C
    mov r1, #1
    str r1, [r0]


@    4) ----------- Configuração do TZIC  -------------------------------------
    @ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE

    ldr	r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]


@    5) ----------- Execução de código de usuário -----------------------------
    @ Você pode fazer isso aqui....
    msr  CPSR_c,  #0x13   @ SUPERVISOR mode, IRQ/FIQ enabled
    loop:
        b loop


@   Rotina para o tratamento de chamadas de sistemas, feitas pelo usuário
@   As funções na camada BiCo fazem syscalls que são tratadas por essa rotina
@   Esta rotina deve, determinar qual syscall foi realizada e realizar alguma ação (escrever nos motores, ler contador de tempo, ....)
svc_handler:

@   Rotina para o tratamento de interrupções IRQ
@   Sempre que uma interrupção do tipo IRQ acontece, esta rotina é executada. O GPT, quando configurado, gera uma interrupção do tipo IRQ. Neste caso, o contador de tempo pode ser incrementado (este incremento corresponde a 1 unidade de tempo do seu sistema)
irq_handler:
    push {r0, r1}

        ldr r0, =0x53FA0008
        mov r1, #1
        str r1, [r0]

        ldr r0, =counter
        ldr r1, [r0]
        add r1, r1, #1
        str r1, [r0]

    pop {r0, r1}
    movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      Seção de Dados                        @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Nesta seção ficam todas as váriaveis utilizadas para execução do código deste arquivo (.word / .skip)
.data
counter: .word 0x00000000
pilha: .skip 64
inicio_pilha: .skip 4
