@ Este arquivo é segmentado 4 partes (questão de legibilidade)
@   * Seção para declaração de contantes    : Onde as contantes são declaradas
@   * Seção do vetor de interrupções        : Código referente ao vetor de interrupções
@   * Seção de texto                        : Onde as rotinas são escritas
@   * Seção de dados                        : Onde são adicionadas as variáveis (.word, .skip) utilizadas neste arquivo


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      Seção de Constantes/Defines           @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ Constante para definição do tempo pra o incremento do contador
    .set TIME_SZ,                    200

@ Constantes para os Modos de operação do Processador, utilizados para trocar entre modos de operação (5 bits menos significativos)
    @ Valores para usar com FIQ/IRQ ativos
    .set MODE_USER,                 0x10
    .set MODE_IRQ,                  0x12
    .set MODE_SUPERVISOR,           0x13
    .set MODE_SYSTEM,               0x1F

@ Constantes referentes aos endereços
	.set USER_ADDRESS,				0x77812000      @ Endereço do código de usuário
	.set STACK_POINTER_IRQ,			0x7E000000      @ Endereço inicial da pilha do modo IRQ
	.set STACK_POINTER_SUPERVISOR,	0x7F000000      @ Endereço inicial da pilha do modo Supervisor
	.set STACK_POINTER_USER, 		0x80000000      @ Endereço inicial da pilha do modo Usuário

@ Constantes referentes aos endereços dos registradores do GPIO
    .set GPIO_DR,                    0x53F84000      @ Endereço do registrador DR do GPIO
    .set GPIO_GDIR,                  0x53F84004      @ Endereço do registrador GDIR do GPIO
    .set GPIO_PSR,                  0x53F84008      @ Endereço do registrador PSR do GPIO

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

    @Escrever 0x41 no GPT_CR
    ldr r0, =0x53FA0000
    mov r1, #0x41
    str r1, [r0]

    @Zerar o prescaler
    ldr r0, =0x53FA0004
    mov r1, #0x0
    str r1, [r0]

    @TIME_SZ no ocr1
    ldr r0, =0x53FA0010
    mov r1, #TIME_SZ
    str r1, [r0]

    @1 no IR
    ldr r0, =0x53FA000C
    mov r1, #1
    str r1, [r0]

    @ Configuracao de entradas e saidas
    ldr r0, =GPIO_GDIR
    ldr r1, =0b01111100000000000011111111111111
    str r1, [r0]

    @ Inicializando o GPIO_DR
    ldr r0, =GPIO_DR
    mov r1, #0x0
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
    msr CPSR_c,  #MODE_USER   @ USER mode, IRQ/FIQ enabled
    mov sp, #STACK_POINTER_USER
    ldr pc, =USER_ADDRESS

@   Rotina para o tratamento de chamadas de sistemas, feitas pelo usuário
@   As funções na camada BiCo fazem syscalls que são tratadas por essa rotina
@   Esta rotina deve, determinar qual syscall foi realizada e realizar alguma ação (escrever nos motores, ler contador de tempo, ....)
svc_handler:

    cmp r7, #17
    bne set_t
    @-----Get time------
        ldr r0, =contador
        ldr r0, [r0]
        movs pc, lr
    @-------------------

    set_t:
    cmp r7, #18
    bne set_m
    @-----Set time------
        ldr r1, =contador
        str r0, [r1]
        movs pc, lr
    @-------------------

    set_m:
    cmp r7, #20
    bne read_s
    @-----Set motor-----
		cmp r0, #0							@ if (r0 == 0)
		beq motor0							@ setar motor0
		cmp r0, #1							@ else if (r0 == 1)
		beq motor1							@ setar motor1
		mov r0, #-1							@ else
		b fim_setar_motor					@ motor invalido

		motor0:
			cmp r1, #63						@ if (r1 > 63)
			movgt r0, #-2					@ velocidade invalida
			bgt fim_setar_motor

			mov r1, r1, lsl #7				@ escreve em r1 os bits correspondentes a velocidade
			orr r1, r1, #0b1000000			@ escreve 1 no bit motor1_write (pra nao modificar a velocidade dele)
			ldr r0, =GPIO_DR
			str r1, [r0]					@ GPIO_DR = r1
			mov r0, #0
			b fim_setar_motor

		motor1:
			cmp r1, #63						@ if (r1 > 63)
			movgt r0, #-2					@ velocidade invalida
			bgt fim_setar_motor

			orr r1, r1, #0b10000000000000	@ escreve 1 no bit motor0_write (pra nao modificar a velocidade dele)
			ldr r0, =GPIO_DR
			str r1, [r0]					@ GPIO_DR = r1
			mov r0, #0
			b fim_setar_motor

		fim_setar_motor:

        movs pc, lr
    @-------------------

    read_s:
    cmp r7, #21
    bne invalid_syscall_code
    @-----Read sonar----
        @---Escrever o ID no MUX---
            mov r0, r0, lsl #26 @ Em r0 temos uma mascara com os bits do id
            ldr r1, =GPIO_DR
            ldr r1, [r1] @ Em r1 temos o numero de dr a ter os bits do mux alterados

            orr r1, r0, r1 @ É feito um OR entre os dois numeros (mantem os bits de r1 que nao sao do mux)
            eor r0, r0, #1  @ XOR com 1 na mascara para barrar todos os bits (a xor 1 equivale a not a)

            mov r0, r0, lsr #26
            mov r0, r0, lsl #28
            mov r0, r0, lsr #2  @ Zera os bits da mascara que nao vao pro mux

            eor r1, r0, r1  @ XOR da nova mascara com o resultado do primeiro OR

            @ As operacoes vao fazer com que exatamente os 4 bits de id sejam escritos nos bits de mux sem alterar o resto.

            ldr r0, =GPIO_DR
            str r1, [r0]

            bl atualiza

            ldr r0, =GPIO_DR
            ldr r1, [r0]
            mov r0, r1, lsr #14

        movs pc, lr
    @-------------------

    invalid_syscall_code:
        movs pc, lr

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

atualiza:
    ldr r0, =GPIO_DR
    ldr r1, [r0]
    @---Escrever 0 no trigger----
        and r1, r1, #0xBFFFFFFF
        str r1, [r0]

    @---Delay 15ms---------------
        ldr r2, =contador
        ldr r2, [r2]
        ldr r3, =15000
        add r2, r2, r3
        primeiro_delay:
        ldr r3, =contador
        ldr r3, [r3]
        cmp r2, r3
        bgt primeiro_delay

    @---Escrever 1 no trigger
        orr r1, r1, #0x40000000
        str r1, [r0]

    @---Delay 15ms---------------
        ldr r2, =contador
        ldr r2, [r2]
        ldr r3, =15000
        add r2, r2, r3
        segundo_delay:
        ldr r3, =contador
        ldr r3, [r3]
        cmp r2, r3
        bgt segundo_delay

    @---Escrever 0 no trigger----
        and r1, r1, #0xBFFFFFFF
        str r1, [r0]

    @---Verificar Flag-----------
        verifica_flag:
            ldr r2, [r0]
            mov r2, r2, lsr #31
            cmp r2, #1
            beq fim_atualiza
    @---Delay 10ms---------------
        ldr r2, =contador
        ldr r2, [r2]
        ldr r3, =10000
        add r2, r2, r3
        terceiro_delay:
        ldr r3, =contador
        ldr r3, [r3]
        cmp r2, r3
        bgt terceiro_delay
        b verifica_flag

    fim_atualiza:
        ldr r2, [r0]
        mov r2, r2, lsl #1
        mov r2, r2, lsr #1
        str r2, [r0]
    mov pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      Seção de Dados                        @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Nesta seção ficam todas as váriaveis utilizadas para execução do código deste arquivo (.word / .skip)
.data
counter: .word 0x00000000
pilha: .skip 64
inicio_pilha: .skip 4
