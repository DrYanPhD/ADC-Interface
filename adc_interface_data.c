#include <stdio.h>
#include "platform.h"
#include "xgpio.h"
#include "xil_printf.h"


int main()
{
    init_platform();

    XGpio adc_input[16], adc_output[16], adc_data_valid_input, adc_data_valid_output, adc_data_last_input, adc_data_last_output; // axi inputs and outputs
    int temp[16], iterations, valid_temp, last_temp;
    int o_adc_output;

    XGpio_Initialize(adc_input, XPAR_GPIO_0_DEVICE_ID); //initialize axi gpio 0
    XGpio_Initialize(&adc_output, XPAR_GPIO_1_DEVICE_ID); // initialize axi gpio 1
    XGpio_Initialize(&adc_data_valid_input, XPAR_GPIO_2_DEVICE_ID); // initialize axi gpio 2
    XGpio_Initialize(&adc_data_valid_output, XPAR_GPIO_3_DEVICE_ID); // initialize axi gpio 3
    XGpio_Initialize(&adc_data_last_input, XPAR_GPIO_4_DEVICE_ID); // initialize axi gpio 4
    XGpio_Initialize(&adc_data_last_output, XPAR_GPIO_5_DEVICE_ID); // initialize axi gpio 5

    // input = 1, output = 0
    XGpio_SetDataDirection(adc_input, 1, 1111); // declares the direction of adc_input
    XGpio_SetDataDirection(adc_output, 1, 0000); // declares the output direction of adc_output
    XGpio_SetDataDirection(&adc_data_valid_input, 1, 1);
    XGpio_SetDataDirection(&adc_data_valid_output, 1, 0);
    XGpio_SetDataDirection(&adc_data_last_input, 1, 1);
    XGpio_SetDataDirection(&adc_data_last_output, 1, 0);

    iterations = 0;

    while (1)
    {
    	printf("ADC Data at Iteration %d: ", iterations);
    	XGpio_DiscreteWrite(&adc_output, 1, adc_input); // prints ADC data one bit at a time
  
    	printf("\n");

    	valid_temp = XGpio_DiscreteRead(&adc_data_valid_input, 1); // stores adc_data_valid_input into a temp var
    	printf("ADC Data Valid at Iteration %d: ", iterations); // prints prompt
    	XGpio_DiscreteWrite(&adc_data_valid_output, 1, valid_temp); // prints temp var
    	printf("\n"); // prints new line

    	last_temp = XGpio_DiscreteRead(&adc_data_last_input, 1); // stores adc_data_last into a temp var
    	printf("ADC Data Last at Iteration %d: ", iterations); // prints prompt
    	XGpio_DiscreteWrite(&adc_data_last_output, 1, last_temp); // prints temp var
    	printf("\n"); // prints new line

    	iterations++; // increments iterations
    }

    cleanup_platform();
    return 0;
}
