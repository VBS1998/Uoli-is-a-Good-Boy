
#include "api_robot.h"

#define LIMIAR 1000				// decidir bons valores para o
#define NORMALSPEED 30			// limiar, velocidade padrao,
#define TOLERANCIA_DIST 20		// tolerancia da distancia a parede,
#define VELOC_PAREDE 7			// e velocidade de seguir parede


int acharSonarMaisProximo (int *array, int size);
void ajustar_posicao(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances);
void seguir_parede(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances);
void ajustar_posicao_parede (motor_cfg_t *motor0, motor_cfg_t *motor1, int distanciaIdeal);
void virar (motor_cfg_t *motor);

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

	ajustar_posicao(&motor0, &motor1, sonarDistances);
	seguir_parede(&motor0, &motor1, sonarDistances);

}


void ajustar_posicao(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances) {

	int closestSonar;

	motor0->speed = 5;
	motor1->speed = 0;
	set_motor_speed(motor1);			// velocidade ajustada para
	set_motor_speed(motor0);			// curva a esquerda

	do {
		motor0->speed = 20;
		set_motor_speed(motor0);
		motor0->speed = 0;
		set_motor_speed(motor0);
		closestSonar = acharSonarMaisProximo(sonarDistances, 16);
	} while (closestSonar != 7);	// sonares referentes ao lado direito do Uoli

	// apos esse laco a parede deve estar posicionada a direita do Uoli

	motor0->speed = VELOC_PAREDE;
	motor1->speed = VELOC_PAREDE;
	set_motor_speed(motor0);			// velocidade reajustada
	set_motor_speed(motor1);			// para a velocidade padrao

}


void seguir_parede(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances) {

	int distanciaIdeal = read_sonar(7);	// sonar a direita do Uoli
	int distanciaAtual;


	while (1) {
		if (read_sonar(3) < LIMIAR || read_sonar(4) < LIMIAR) {
			ajustar_posicao(motor0, motor1, sonarDistances);
			continue;
		}
		distanciaAtual = read_sonar(7);
		if (distanciaAtual > distanciaIdeal + TOLERANCIA_DIST) {
			ajustar_posicao_parede(motor1, motor0, distanciaIdeal);	// aproximar da parede
			distanciaIdeal = read_sonar(7);
		} else if (distanciaAtual < distanciaIdeal - TOLERANCIA_DIST) {
			//ajustar_posicao_parede(motor0, motor1, distanciaIdeal);	// afastar da parede
			//distanciaIdeal = read_sonar(7);
			virar(motor0);
		}

	}

}

/*
 * retorna o indice do sonar mais proximo da parede.
 */
int acharSonarMaisProximo (int *array, int size) {

	int min = 5;
	array[5] = read_sonar(5);
	for (int i = 6; i < 8; i++) {
		array[i] = read_sonar(i);
		if (array[i] < array[min]) {
			min = i;
		}
	}

	return min;

}

void virar (motor_cfg_t *motor) {
	motor->speed = 35;
	set_motor_speed(motor);
	motor->speed = VELOC_PAREDE;
	set_motor_speed(motor);
}


void ajustar_posicao_parede (motor_cfg_t *motor0, motor_cfg_t *motor1, int distanciaIdeal) {

	motor0->speed = 5;
	motor1->speed = 0;
	set_motor_speed(motor1);			// velocidade ajustada para
	set_motor_speed(motor0);			// curva a esquerda

	do {
		motor0->speed = 20;
		set_motor_speed(motor0);
		motor0->speed = 0;
		set_motor_speed(motor0);
	} while ((read_sonar(7) < distanciaIdeal - TOLERANCIA_DIST) || (read_sonar(7) > distanciaIdeal + TOLERANCIA_DIST));	// sonares referentes ao lado direito do Uoli

	// apos esse laco a parede deve estar posicionada a direita do Uoli

	motor0->speed = VELOC_PAREDE;
	motor1->speed = VELOC_PAREDE;
	set_motor_speed(motor0);			// velocidade reajustada
	set_motor_speed(motor1);			// para a velocidade padrao

}



/*
#include "api_robot.h"

#define VEL_RETO 60
#define LIMIAR 1200

void _start() {

	motor_cfg_t motor0, motor1;
	motor0.id = 0;
	motor1.id = 1;

	motor0.speed = VEL_RETO;
	motor1.speed = VEL_RETO;

	set_motor_speed(&motor0);
	set_motor_speed(&motor1);

	while (1) {
		if (read_sonar(3) < LIMIAR || read_sonar(4) < LIMIAR) {
			motor0.speed = 0;
			motor1.speed = 0;
			set_motor_speed(&motor0);
			set_motor_speed(&motor1);
		}
	}

}
*/

/*
#include "api_robot.h"

void _start(){

	int volatile * const p_reg = (int *) 0x8000000;
	*p_reg = 0x7;

	while(1){
		*p_reg = read_sonar(3);
	}
}
*/
