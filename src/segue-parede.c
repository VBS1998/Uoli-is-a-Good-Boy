
#include "api_robot.h"

#define LIMIAR 700				// decidir bons valores para o
#define NORMALSPEED 8			// limiar, velocidade padrao,
#define TOLERANCIA_DIST 10		// tolerancia da distancia a parede,
#define SPEED_PAREDE 5			// e velocidade de seguir parede
#define DIST_SEM_OBSTACULO 2000


//int acharSonarMaisProximo (int *array, int size);
void ajustar_posicao(motor_cfg_t *motor0, motor_cfg_t *motor1);
void seguir_parede(motor_cfg_t *motor0, motor_cfg_t *motor1);
//void ajustar_posicao_parede (motor_cfg_t *motor0, motor_cfg_t *motor1, int distanciaIdeal);
//void virar (motor_cfg_t *motor);

void _start() {

	motor_cfg_t motor0, motor1;
	int sonarDistances[16];
	motor0.id = 0;
	motor1.id = 1;

	// Busca a parede:

	motor0.speed = NORMALSPEED;
	motor1.speed = NORMALSPEED;
	set_motor_speed(&motor0);
	set_motor_speed(&motor1);

	while(read_sonar(3) > LIMIAR && read_sonar(4) > LIMIAR) {
		// Uoli deve andar reto ate encontrar uma parede
	}

	ajustar_posicao(&motor0, &motor1);
	seguir_parede(&motor0, &motor1);

}


void ajustar_posicao(motor_cfg_t *motor0, motor_cfg_t *motor1) {

	motor1->speed = 0;
	set_motor_speed(motor1);	// Uoli comeca a virar para a direita

	while (read_sonar(3) < LIMIAR || read_sonar(4) < LIMIAR) {
		// Uoli deve permanecer virando pra direita ate estar de lado pra parede
	}

	motor1->speed = NORMALSPEED;
	set_motor_speed(motor1);

}


void seguir_parede(motor_cfg_t *motor0, motor_cfg_t *motor1) {

	int sonar7, sonar8;
	int fazendoCurvaDireita = 0, fazendoCurvaEsquerda = 0;

	motor0->speed = SPEED_PAREDE;
	motor1->speed = SPEED_PAREDE;
	set_motor_speed(motor0);
	set_motor_speed(motor1);

	while(1) {

		if(read_sonar(4) < LIMIAR){
			if(fazendoCurvaDireita){
				motor0->speed = SPEED_PAREDE;
				set_motor_speed(motor0);
				fazendoCurvaDireita = 0;
			}
			motor1->speed = 0;
			set_motor_speed(motor1);
			fazendoCurvaEsquerda = 1;
			while(read_sonar(4) < LIMIAR){}
			motor1->speed = SPEED_PAREDE;
			set_motor_speed(motor1);
			fazendoCurvaEsquerda = 0;
		}

		sonar7 = read_sonar(7);
		if (sonar7 > 2000) {
			if (fazendoCurvaEsquerda) {
				motor1->speed = SPEED_PAREDE;
				set_motor_speed(motor1);
				fazendoCurvaEsquerda = 0;
			}
			motor0->speed = 0;
			set_motor_speed(motor0);
			fazendoCurvaDireita = 1;
			while(read_sonar(7) > 2000){}
			motor0->speed = SPEED_PAREDE;
			set_motor_speed(motor0);
			fazendoCurvaDireita = 0;
		}
		sonar8 = read_sonar(8);
		if (sonar7 > sonar8) {
			if ((sonar7 - sonar8) > TOLERANCIA_DIST) {
				if (fazendoCurvaEsquerda) {
					motor1->speed = SPEED_PAREDE;
					set_motor_speed(motor1);
					fazendoCurvaEsquerda = 0;
				}
				if (!fazendoCurvaDireita) {
					motor0->speed = 0;
					set_motor_speed(motor0);
					fazendoCurvaDireita = 1;
				}
				continue;
			}
		} else {
			if ((sonar8 - sonar7) > TOLERANCIA_DIST) {
				if (fazendoCurvaDireita) {
					motor0->speed = SPEED_PAREDE;
					set_motor_speed(motor0);
					fazendoCurvaDireita = 0;
				}
				if (!fazendoCurvaEsquerda) {
					motor1->speed = 0;
					set_motor_speed(motor1);
					fazendoCurvaEsquerda = 1;
				}
				continue;
			}
		}

		if (fazendoCurvaDireita) {
			motor0->speed = SPEED_PAREDE;
			set_motor_speed(motor0);
			fazendoCurvaDireita = 0;
		} else if (fazendoCurvaEsquerda) {
			motor1->speed = SPEED_PAREDE;
			set_motor_speed(motor1);
			fazendoCurvaEsquerda = 0;
		}


	}

}
