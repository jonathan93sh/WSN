#include "friendDetector.h"
module friendDetectorC{
	uses {
		interface Boot;
		interface Disco;	
		interface Leds;
	}
}
implementation{
	


	event error_t Disco.fetchPayload(void *buf, uint8_t *len,uint16_t nodeid){
		// TODO Auto-generated method stub
		const char msgString[] = "Friend";
		strcpy(buf, msgString);
		*len = (uint8_t)strlen(msgString)+1;
		return SUCCESS;
	}

	event message_t Disco.received(message_t *msg, void *buf, uint8_t len, uint16_t nodeid){
		if(len==0)//beacon message
		{
			call Disco.requestBroadcast();	
			call Leds.led2Toggle();	
			printf("msg: beacon\r\n");
		}
		else if(strncmp(buf, "Friend", len)==0) //Looking for friend message
		{
			call Leds.led0On();
			printf("msg: %s\r\n", (char *)buf);
		}
		else
		{
			call Leds.led0Off();
			printf("msg: %s\r\n", (char *)buf);
		}
		return *msg;
	}

	event void Boot.booted(){
		call Leds.led0Off();
		call Leds.led2Off();
		call Disco.setBeaconMode(TRUE);
		call Disco.setNodeClass(TOS_NODE_ID);
		call Disco.setDutyCycle(5);
		call Leds.led1On();
		printf("Boot done");
		//call Leds.set(0xFF);
	}
}