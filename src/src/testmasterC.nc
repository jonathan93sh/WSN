#include "friendDetector.h"
module friendDetectorC{
	uses {
		interface Boot;
		interface Disco;	
		interface Leds;
		interface Timer<TMilli> as Timer0;
		interface Counter<TMilli, uint32_t> as Counter0;
	}
}
implementation{
	uint32_t lastDisco = 0;
	uint32_t counter_reset_value = 100;
	uint32_t countdown = 0;
	

	event error_t Disco.fetchPayload(void *buf, uint8_t *len,uint16_t nodeid){
		// TODO Auto-generated method stub
		const char msgString[] = "Friend";
		strcpy(buf, msgString);
		*len = (uint8_t)strlen(msgString)+1;
		return SUCCESS;
	}

	event message_t Disco.received(message_t *msg, void *buf, uint8_t len, uint16_t nodeid){
		uint32_t nowDisco = call Counter0.get();
		if(len==0)//beacon message
		{
			call Disco.requestBroadcast();	
			call Leds.led2Toggle();	
			printf("msg: beacon, time since last beacon: %lu ms\r\n", nowDisco-lastDisco);
			lastDisco = nowDisco;
		}
		else if(strncmp(buf, "Friend", len)==0) //Looking for friend message
		{
			call Leds.led0On();
			//printf("msg: %s\r\n", (char *)buf);
			call Timer0.stop();
			call Timer0.startOneShot(10000);
		}
		else
		{
			call Leds.led0Off();
			printf("got wrong msg: %s\r\n", (char *)buf);
		}
		return *msg;
	}

	event void Boot.booted(){
		call Leds.led0Off();
		call Leds.led2Off();
		call Disco.setBeaconMode(TRUE);
		call Disco.setNodeClass(TOS_NODE_ID);
		call Disco.setDutyCycle(2.5,0);
		call Leds.led1On();
		printf("Boot done\r\n");
		lastDisco = call Counter0.get();
		//call Leds.set(0xFF);
	}

	event void Timer0.fired(){
		printf("No friends left\r\n");
		call Leds.led0Off();
	}

	async event void Counter0.overflow(){
		// TODO Auto-generated method stub
	}
}