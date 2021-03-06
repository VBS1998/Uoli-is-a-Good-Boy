.text
.align 4

.globl set_motor_speed
.globl read_sonar
.globl set_time
.globl get_time


set_motor_speed:
	push {r7, lr}
	ldrb r2, [r0]		@ id do motor em r2
	ldrb r1, [r0, #1]	@ speed em r1
	mov r0, r2			@ id do motor em r0
	mov r7, #20			@ codigo da syscall set_motor_speed
	svc 0x0				@ chamada da syscall (ja poe o retorno em r0)
	pop {r7, pc}


read_sonar:
	push {r7, lr}
	mov r7, #21			@ codigo da syscall read_sonar
	svc 0x0				@ le o sonar e poe a distancia lida em r0 (retorno da funcao)
	pop {r7, pc}


get_time:
	push {r7, lr}
	mov r7, #17			@ codigo da syscall get_time
	svc 0x0				@ retorna o tempo e poe em r0
	pop {r7, pc}


set_time:
	push {r7, lr}
	mov r7, #18			@ codigo da syscall set_time
	svc 0x0				@ seta o tempo com valor de r0
	pop {r7, pc}
