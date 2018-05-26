#include "testmaster.h"
#include "Disco.h"
module testslaveC{
	uses {
		interface Boot;
		interface Disco;	
		interface Leds;
	}
}
implementation{
	
	
	
	event error_t Disco.fetchPayload(DiscoMsg *msg,void *buf, uint8_t *len){
		return FAIL;
	}

	event void Disco.received(DiscoMsg *msg, void *buf, uint8_t len){
		testMsg newMsg;
		
		if(len==0)
		{
			call Disco.requestBroadcast();
		}
		else if(len==sizeof(testMsg))
		{
			memcpy(&newMsg,buf,(size_t)len);
			
			call Disco.setDutyCycleIndex(newMsg.next_prim_pair_idx,rand());
		}
	}

	event void Boot.booted(){
		call Leds.led0Off();
		call Leds.led2Off();
		call Disco.setBeaconMode(FALSE);
		call Disco.setNodeClass(TOS_NODE_ID);
		call Disco.setDutyCycleIndex(0,rand());
		call Leds.led1On();
		printf("Boot done\r\n");
	}

}