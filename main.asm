//*****************************************************************************
//Universidad del Valle de Guatemala 
//Programación de Microprocesadores 
//Archivo:Laboratorio_03
//Hardware:ATMEGA328P
//Autor:Adriana Marcela Gonzalez 
//Carnet:22438
//*****************************************************************************
// Encabezado 
//*****************************************************************************
.include "M328PDEF.inc"
.cseg
.org 0x0000
	JMP Setup
.org 0x0006
	JMP ISR_INT0
.org 0x0020
	JMP Timer_TMR0

//*****************************************************************************
// Stack pointer
//*****************************************************************************

Setup:
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17

//*****************************************************************************
// Configuración 
//*****************************************************************************
	
//Asignar la tabla de valores del 7 segmentos
	LDI ZH, HIGH(Tabla7seg << 1)
	LDI ZL, LOW(Tabla7seg << 1)

//Configuración 1 MHz
	LDI R16, (1 << CLKPCE) //Habilitar el prescaler
	STS CLKPR, R16
	LDI R16, 0b0000_0100
	STS CLKPR, R16

	LDI	R16, 0x00	//Deshabilitando RX y TX para usarlos como puertos
	STS	UCSR0B, R16		
	LDI R16, 0b1111_1111
	OUT DDRD, R16 //Habilitar el puerto D como salida

	CALL Timer_TMR0

//Habilitar los puertos de salida para los transistores
	LDI	R16, (1 << DDB2) | (1 << DDB3)  // PB2 y PB3 como salida
	OUT	DDRB, R16

	LDI R16, 0b1111_1111
	OUT DDRC, R16 //Habilitar el puerto C como salida

	LDI R16, 0b0000_0000
	OUT DDRB, R16 //Habilitar el puerto B como entrada

//Setear el contador 
	LDI	R18, 0x00		
	
	LDI	R16, (1 << PCINT0) | (1 << PCINT1)
	STS	PCMSK0, R16
	LDI	R16, (1 << PCIE0)
	STS	PCICR, R16

//Activar las interrupciones globales 
	SEI

//*****************************************************************************
// Main
//*****************************************************************************

//Tabla de valores para el display desde el 0 al 9
Tabla7seg: .DB 0x01, 0x4F, 0x12, 0x06, 0x4C, 0x24, 0x20, 0x0F, 0x00, 0x04

Loop:
	//Salida del contador del timer 0
	OUT	PORTC, R21

	//Display de segundos
	SBI	PORTB, PB2 
	LDI	ZL, LOW(Tabla7seg << 1)
	ADD	ZL, R18
	LPM	R19, Z
	OUT	PORTD, R19
	CALL Delaycito
	CBI	PORTB, PB2

	//Display de decenas de segundos 
	SBI	PORTB, PB3
	LDI	ZL, LOW(Tabla7seg << 1)
	ADD	ZL, R20
	LPM	R22, Z
	OUT	PORTD, R22
	CALL Delaycito
	CBI	PORTB, PB3

	//Comparador para resetear ambos contadores cuando sean maximos
	CPI	R21, 100
	BRNE Loop
	CLR	R21
	INC	R18
	CPI	R18, 0b0000_1010
	BREQ Reset
	RJMP Loop 	

//****************************************************************************
// Subrutinas
//*****************************************************************************
//Subrutinas de reinicio de los contadores
Reset:
	LDI	ZL, LOW(Tabla7seg << 1)
	//Asignar 0 al contador de segundos 
	LDI	R18, 0x00
	INC	R20
	CPI	R20, 0b0000_0110
	BREQ Reset_2
	RJMP Loop
	
Reset_2:
	//Asignar 0 al contador de decenas
	LDI	R20, 0x00
	RJMP Loop

Timer_TMR0: 
	LDI	R16, (1 << CS02) | (1 << CS00) //Configuración 1024 prescaler 
	OUT	TCCR0B, R16
	LDI R16, 99		//Valor de descordamiento
	OUT	TCNT0, R16	//Valor inicial del contador
	LDI	R16, (1<<TOIE0)
	STS	TIMSK0, R16	
	RET

ISR_INT0:
	PUSH R16
	IN R16, SREG
	PUSH R16
	IN R16, PINB
	SBRC R16, PB0
	RJMP Rest
	INC	R23
	SBRC R23, 4
	CLR	R23
	RJMP jump

Rest:
	SBRS R16, PB1
	DEC	R23
	SBRC R23, 4
	LDI	R23, 0x0F
	RJMP jump

jump:
	SBI	PCIFR, PCIF0
	POP	R16
	OUT	SREG, R16
	POP	R16
	RETI 

//*****************************************************************************
// TIMER 0 OVER
//*****************************************************************************
ISR_TIMER0_OVF:
	PUSH R16
	IN R16, SREG
	PUSH R16

	LDI	R16, 99
	OUT	TCNT0, R16
	SBI	TIFR0, TOV0
	INC	R20

	POP	R16
	OUT	SREG, R16
	POP	R16
	RETI

Delaycito:
	LDI R16, 100
	Delay:
	DEC R16
	BRNE Delay
	RET
