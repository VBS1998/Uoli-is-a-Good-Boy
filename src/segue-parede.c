//
// #include "api_robot.h"
//
// #define LIMIAR 1200				// decidir bons valores para o
// #define NORMALSPEED 30			// limiar, velocidade padrao,
// #define TOLERANCIA_DIST 100		// tolerancia da distancia a parede,
// #define TEMPO_CURVA 100			// e tempo de curva
//
//
// int acharSonarMaisProximo (int *array, int size);
//
// void _start() {
//
// 	motor_cfg_t motor0, motor1;
// 	int sonarDistances[16];
// 	motor0.id = 0;
// 	motor1.id = 1;
//
// 	// Busca a parede:
//
// 	motor0.speed = NORMALSPEED;
// 	motor1.speed = NORMALSPEED;
// 	set_motor_speed(&motor0);
// 	set_motor_speed(&motor1);
//
// 	int aux = 0;
// 	while(read_sonar(3) > LIMIAR && read_sonar(4) > LIMIAR){
// 		aux++;
// 		aux--;
// 	}
// }
//
// 	// Ajusta a posicao:
// 	int closestSonar;
//
// 	motor0.speed = 10;
// 	motor1.speed = 0;
// 	set_motor_speed(&motor0);			// velocidade ajustada para
// 	set_motor_speed(&motor1);			// curva a esquerda
//
// 	do {
// 		closestSonar = acharSonarMaisProximo(sonarDistances, 16);
// 	} while ((closestSonar != 7) && (closestSonar != 8));	// sonares referentes ao lado direito do Uoli
//
// 	// apos esse laco a parede deve estar posicionada a direita do Uoli
//
// 	motor0.speed = NORMALSPEED;
// 	motor1.speed = NORMALSPEED;
// 	set_motor_speed(&motor0);			// velocidade reajustada
// 	set_motor_speed(&motor1);			// para a velocidade padrao
//
//
// 	// Segue a parede:
//
// 	int distanciaIdeal = read_sonar(7);	// sonar a direita do Uoli
// 	int distanciaAtual;
//
//
// 	while (1) {
// 		if (read_sonar(3) < LIMIAR || read_sonar(4) < LIMIAR) {
// 			set_time(0);
// 			motor1.speed = 0;
// 			set_motor_speed(&motor1);
// 			while (get_time() < TEMPO_CURVA) {
// 				// esperar o tempo de curva
// 			}
// 			motor1.speed = NORMALSPEED;
// 			set_motor_speed(&motor1);
// 			continue;
// 		}
// 		distanciaAtual = read_sonar(7);
// 		if (distanciaAtual > (distanciaIdeal + TOLERANCIA_DIST)) {
// 			// aproximar da parede
// 			while(distanciaAtual > (distanciaIdeal + TOLERANCIA_DIST)){
// 				motor0.speed = 0;
// 				set_motor_speed(&motor0);
// 			}
// 		} else if (distanciaAtual < (distanciaIdeal - TOLERANCIA_DIST)) {
// 			// afastar da parede
// 			while(distanciaAtual > (distanciaIdeal - TOLERANCIA_DIST)){
// 				motor1.speed = 0;
// 				set_motor_speed(&motor1);
// 			}
// 		}
//
// 	}
//
//
// 	return 0;
//
// }
//
// /*
//  * retorna o indice do sonar mais proximo da parede.
//  */
//
// int acharSonarMaisProximo (int *array, int size) {
//
// 	int min = 0;
// 	array[0] = read_sonar(0);
// 	for (int i = 1; i < size; i++) {
// 		array[i] = read_sonar(i);
// 		if (array[i] < array[min]) {
// 			min = i;
// 		}
// 	}
//
// 	return min;
//
// }
// #include "api_robot.h"
//
// #define VEL_RETO 30
//
// void segue_parede() {
//     motor_cfg_t motor0, motor1;
//     motor0.id = 0;
//     motor1.id = 1;
//
//     motor0.speed = VEL_RETO;
//     motor1.speed = VEL_RETO;
//
//     set_motor_speed(&motor0);
//     set_motor_speed(&motor1);
//
// 	int aux;
//     while(1){
// 		aux++;
// 	}
//
// }

#include "api_robot.h"

void _start(){

	int volatile * const p_reg = (int *) 0x8000000;
	*p_reg = 0x7;

	while(1){
		*p_reg = read_sonar(3);
	}
}
