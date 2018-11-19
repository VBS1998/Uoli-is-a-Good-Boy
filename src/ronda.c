#include "api_robot.h"

int _start(){

    motor_cfg_t *motor = malloc(sizeof(motor_cfg_t));

    while(1){
        for(int t = 1; t <= 50; t=t+2){
            set_time(0);

            //vai para frente:
            motor->id = 0;
            motor->speed = 30;
            set_motor_speed(motor);
            motor->id = 1;
            motor->speed = 30;
            set_motor_speed(motor);
            while(get_time() < t*250){ //com t*250, usamos a unidade de tempo como 0,25 segundos
                
            }

        }

    }
    free(motor);
}
