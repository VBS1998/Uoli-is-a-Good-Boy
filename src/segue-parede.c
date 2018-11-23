/*
#include "api_robot.h"

#define LIMIAR 1200				// decidir bons valores para o
#define NORMALSPEED 30			// limiar, velocidade padrao,
#define TOLERANCIA_DIST 2		// tolerancia da distancia a parede,
#define VELOC_PAREDE 15			// e velocidade de seguir parede


int acharSonarMaisProximo (int *array, int size);
void ajustar_posicao(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances);
void seguir_parede(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances);

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

	while(read_sonar(3) > LIMIAR && read_sonar(4) > LIMIAR){
		// Uoli deve andar reto ate encontrar uma parede
	}

	ajustar_posicao(&motor0, &motor1, sonarDistances);
	seguir_parede(&motor0, &motor1, sonarDistances);

}


void ajustar_posicao(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances) {

	int closestSonar;

	motor0->speed = 10;
	motor1->speed = 0;
	set_motor_speed(motor0);			// velocidade ajustada para
	set_motor_speed(motor1);			// curva a esquerda

	do {
		closestSonar = acharSonarMaisProximo(sonarDistances, 16);
	} while ((closestSonar != 7) && (closestSonar != 8));	// sonares referentes ao lado direito do Uoli

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
		if (distanciaAtual > (distanciaIdeal + TOLERANCIA_DIST)) {
			ajustar_posicao(motor1, motor0, sonarDistances);	// aproximar da parede
		} else if (distanciaAtual < (distanciaIdeal - TOLERANCIA_DIST)) {
			ajustar_posicao(motor0, motor1, sonarDistances);	// afastar da parede
		}

	}

}

/*
 * retorna o indice do sonar mais proximo da parede.
 *
int acharSonarMaisProximo (int *array, int size) {

	int min = 4;
	array[4] = read_sonar(4);
	for (int i = 4; i < 12; i++) {
		array[i] = read_sonar(i);
		if (array[i] < array[min]) {
			min = i;
		}
	}

	return min;

}
*/



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
		if (read_sonar(3) < LIMIAR) {
			motor0.speed = 0;
			motor1.speed = 0;
			set_motor_speed(&motor0);
			set_motor_speed(&motor1);
		}
	}

}


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
