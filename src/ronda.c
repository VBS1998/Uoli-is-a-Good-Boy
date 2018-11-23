#include "api_robot.h"

#define VEL_RETO 12
#define MOTOR_ESQ 1
#define MOTOR_DIR 0
#define DISTANCIA_PARA_VIRAR 800
#define TEMPO_CURVA 24000

int _start(){

	motor_cfg_t motor;
	int reto;

	while(1){
        for(int t = 1; t <= 50; t=t+2){
			set_time(0);
			//vai para frente:
			motor.id = MOTOR_DIR;
			motor.speed = VEL_RETO;
			set_motor_speed(&motor);
			motor.id = MOTOR_ESQ;
			motor.speed = VEL_RETO;
			set_motor_speed(&motor);
			reto = 1;
			// Vai indo checando paredes:
			while(get_time() < t/2){
					if(read_sonar(3) <= DISTANCIA_PARA_VIRAR || read_sonar(4) <= DISTANCIA_PARA_VIRAR){ //Se encontrar uma parede
						if(reto){ //so seta a speed pra girar se estiver indo reto
							motor.id = MOTOR_DIR;
							motor.speed = 0;
							set_motor_speed(&motor);
						}
						reto = 0;
					} else {
						if(!reto){
							motor.id = MOTOR_DIR;
							motor.speed = VEL_RETO;
							set_motor_speed(&motor);
						}
						reto = 1;
					}
			}

			// Vira 90 graus para a direita:
			set_time(0);
			motor.id = MOTOR_DIR;
			motor.speed = 0;
			set_motor_speed(&motor);
			while(get_time() < TEMPO_CURVA){}
		}

	}
	return 0;
}
