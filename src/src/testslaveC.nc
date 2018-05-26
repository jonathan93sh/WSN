#include "testmaster.h"
#include "Disco.h"
module testSlave{
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
	uint32_t testN = 10;
	uint32_t test_cur = 0;

	uint16_t MprimeIDX[] = {1,2,3,4,5,6,7,8,9,10};
	uint16_t SprimeIDX[] = {1,2,3,4,5,6,7,8,9,10};

	event error_t Disco.fetchPayload(DiscoMsg *msg,void *buf, uint8_t *len){
		uint16_t p1,p2;
		uint32_t nowDisco = call Counter0.get();
		call Disco.getPrimes(&p1,&p2);
		printf("%u,%u,%u,%u,%u\r\n", p1,p2,msg->prime1,msg->prime2,nowDisco-lastDisco);
		lastDisco = nowDisco;
		
		if(countdown == 0)
		{
			countdown=counter_reset_value;
			test_cur++;
		}
		if(test_cur >= testN)
			return FAIL;

		countdown--;

		call Disco.setDutyCycleIndex(MprimeIDX[test_cur],rand());
		
		testMsg.next_prim_pair_idx = SprimeIDX[test_cur];
		memcpy(buf, testMsg,sizeof(testMsg_t));
		*len = sizeof(testMsg_t);

		return SUCCESS;
	}

	event message_t Disco.received(DiscoMsg *msg, void *buf, uint8_t len){
		return *msg;
	}

	event void Boot.booted(){
		call Leds.led0Off();
		call Leds.led2Off();
		call Disco.setBeaconMode(TRUE);
		call Disco.setNodeClass(TOS_NODE_ID);
		call Disco.setDutyCycleIndex(MprimeIDX[0],rand());
		call Leds.led1On();
		printf("Boot done\r\n");
		lastDisco = call Counter0.get();
	}

	async event void Counter0.overflow(){
		// TODO Auto-generated method stub
	}
}