/* SDK 2018.3 standalone, Cortex-A9 CPU0. EGO-XZ7 manual V1.2:
 * LED0 T22, BTNC P16, both active-high. External DDR/UART unused.
 * No button polling: the only button read is inside the hardware IRQ handler.
 * led_state/irq_count/press_count/last_button/app_status are debugger observables.
 */
#include "xparameters.h"
#include "xgpio.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xstatus.h"
#include "xil_cache.h"

#define BUTTON_ID XPAR_AXI_GPIO_BUTTON_DEVICE_ID
#define LED_ID XPAR_AXI_GPIO_LED_DEVICE_ID
#define BUTTON_IRQ XPAR_FABRIC_AXI_GPIO_BUTTON_IP2INTC_IRPT_INTR
#define GIC_ID XPAR_SCUGIC_SINGLE_DEVICE_ID

static XGpio Button, Led;
static XScuGic Gic;
volatile u32 led_state = 1U;
volatile u32 irq_count = 0U;
volatile u32 press_count = 0U;
volatile u32 last_button = 0U;
volatile int app_status = 0;

static void ButtonIsr(void *ref)
{
    XGpio *gpio = (XGpio *)ref;
    u32 pending = XGpio_InterruptGetStatus(gpio) & XGPIO_IR_CH1_MASK;
    if (pending == 0U) return;
    u32 pressed = XGpio_DiscreteRead(gpio, 1U) & 1U;
    /* AXI GPIO IPISR is toggle-on-write, not PS GPIO write-one-to-clear.
     * This BSP API reads status and writes only bits already set.
     */
    XGpio_InterruptClear(gpio, pending);
    ++irq_count;
    if (pressed != 0U && last_button == 0U) {
        ++press_count;
        led_state ^= 1U;
        XGpio_DiscreteWrite(&Led, 1U, led_state);
    }
    last_button = pressed; /* release IRQ arms the next press */
}

int main(void)
{
    int status;
    XScuGic_Config *cfg;
    Xil_ExceptionDisable();
    /* Keep debugger-visible counters coherent with physical OCM reads. */
    Xil_DCacheDisable();
    status = XGpio_Initialize(&Led, LED_ID);
    if (status != XST_SUCCESS) {app_status=-1; return status;}
    XGpio_SetDataDirection(&Led, 1U, 0U);
    XGpio_DiscreteWrite(&Led, 1U, led_state); /* initial LED ON, logical polarity */
    status = XGpio_Initialize(&Button, BUTTON_ID);
    if (status != XST_SUCCESS) {app_status=-2; return status;}
    XGpio_SetDataDirection(&Button, 1U, 1U);
    XGpio_InterruptGlobalDisable(&Button);
    XGpio_InterruptDisable(&Button, XGPIO_IR_CH1_MASK);
    cfg = XScuGic_LookupConfig(GIC_ID);
    if (cfg == 0) {app_status=-3; return XST_FAILURE;}
    status = XScuGic_CfgInitialize(&Gic, cfg, cfg->CpuBaseAddress);
    if (status != XST_SUCCESS) {app_status=-4; return status;}
    /* AXI GPIO asserts a high LEVEL until IPISR is cleared. */
    XScuGic_SetPriorityTriggerType(&Gic, BUTTON_IRQ, 0xA0U, 0x1U);
    status = XScuGic_Connect(&Gic, BUTTON_IRQ, (Xil_ExceptionHandler)ButtonIsr, &Button);
    if (status != XST_SUCCESS) {app_status=-5; return status;}
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler, &Gic);
    XGpio_InterruptClear(&Button, XGPIO_IR_CH1_MASK);
    XScuGic_Enable(&Gic, BUTTON_IRQ);
    XGpio_InterruptEnable(&Button, XGPIO_IR_CH1_MASK);
    XGpio_InterruptGlobalEnable(&Button);
    app_status = 1;
    Xil_ExceptionEnable();
    for (;;) { __asm__ volatile ("wfi"); }
}
