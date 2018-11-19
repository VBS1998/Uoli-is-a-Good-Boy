#include <stdlib.h>
#include "api_robot2.h"

#define LIMIAR 1200				// decidir bons valores para o
#define NORMALSPEED 30			// limiar e velocidade padrao

int main() {

	motor_cfg_t *motor0, *motor1;
	motor0 = malloc(sizeof(motor_cfg_t));
	motor1 = malloc(sizeof(motor_cfg_t));
	int *sonarDistances = malloc(16 * sizeof(int));
	motor0->id = 0;
	motor1->id = 1;

	busca-parede(motor0, motor1, sonarDistances);
	segue-parede(motor0, motor1, sonarDistances);

	free(motor0);
	free(motor1);
	free(sonarDistances);

	return 0;

}



void busca-parede(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances) {

	motor0->speed = NORMALSPEED;
	motor1->speed = NORMALSPEED;
	set_motor_speed(motor0);	// setando a velocidade inicial
	set_motor_speed(motor1);	// dos dois motores em 30

	while (read_sonar(3) > LIMIAR) {
		// Uoli deve seguir em frente ate encontrar um obstaculo
	}

	ajutar-posicao(motor0, motor1, sonarDistances);

}



void segue-parede(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances) {

	int distanciaIdeal = read_sonar(7);	// sonar a direita do Uoli
	int distanciaAtual;


	while (1) {
		if (read_sonar(3) < LIMIAR) {
			// implementar meio de evitar colisao
		}
		distanciaAtual = read_sonar(7);
		if (distanciaAtual > (distanciaIdeal + 100)) {
			// aproximar da parede
		} else if (distanciaAtual < (distanciaIdeal - 100)) {
			// afastar da parede
		}
		
	} 

}



/*
 * ajusta a posicao do Uoli para que a parede fique a sua direita, voltando
 * a velocidade dos motores ao normal no final da funcao para que ele siga a parede.
 */

void ajustar-posicao(motor_cfg_t *motor0, motor_cfg_t *motor1, int *sonarDistances) {

	int closestSonar;

	motor0->speed = 10;
	motor1->speed = 0;
	set_motor_speed(motor0);			// velocidade ajustada para
	set_motor_speed(motor1);			// curva a direita

	do {
		closestSonar = acharSonarMaisProximo(sonarDistances, 16);
	} while ((closestSonar != 7) && (closestSonar != 8));	// sonares referentes ao lado direito do Uoli

	// apos esse laco a parede deve estar posicionada a direita do Uoli

	motor0->speed = NORMALSPEED;
	motor1->speed = NORMALSPEED;
	set_motor_speed(motor0);			// velocidade reajustada
	set_motor_speed(motor1);			// para a velocidade padrao

}



/*
 * retorna o indice do sonar mais proximo da parede.
 */

int acharSonarMaisProximo (int *array, int size) {

	int min = 0;
	array[0] = read_sonar(0);
	for (int i = 1; i < size; i++) {
		array[i] = read_sonar(i);
		if (array[i] < array[min]) {
			min = i;
		}
	}

	return min;

} 

