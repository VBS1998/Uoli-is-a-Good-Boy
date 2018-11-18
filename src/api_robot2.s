.text
.align 4

_start:

set_motor_speed:
	push {r1,r2, r7, lr}
	ldrb r2, [r0]		@ id do motor em r2
	ldrb r1, [r0, #1]	@ speed em r1
	mov r1, r2			@ id do motor em r0
	mov r7, #20			@ codigo da syscall set_motor_speed
	svc 0x0
	pop {r1,r2, r7, pc}


set_motors_speed:
	push {lr}
	bl set_motor_speed	@ set da velocidade do primeiro motor
	mov r0, r1			@ passa o endereco do segundo motor de r1 para r0
	bl set_motor_speed	@ set da velocidade do segundo motor
	pop {pc}


read_sonar:
	push {r7, lr}
	mov r7, #21			@ codigo da syscall read_sonar
	svc 0x0				@ le o sonar e poe a distancia lida em r0 (retorno da funcao)
	pop {r7, pc}


read_sonars:
	push {lr}
 loop_read_sonars:
	bl read_sonar		@ le o sonar de r0
	str r0, [r2], #4	@ guarda o valor da leitura no vetor e incrementa a posicao do vetor
	add r0, r0, #1		@ incrementa r0
	cmp r0, r1			@ if (r0 <= r1)
	ble loop_read_sonar	@ volta ao loop
	pop {pc}


register_proximity_callback:
	push {lr}
	bl read_sonar		@ guarda em r0 a distancia do sonar
	cmp r0, r1			@ if (r0 < r1)
	blxlt r2			@ executa a funcao cujo endereco esta em r2
	pop {pc}


	




