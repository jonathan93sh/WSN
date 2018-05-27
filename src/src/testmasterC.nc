#include "testmaster.h"
#include "Disco.h"

#include <UserButton.h>

	

module testmasterC{
	uses {
		interface Boot;
		interface Disco;	
		interface Leds;
		interface Get<button_state_t>;
		interface Notify<button_state_t>;
		interface Counter<TMilli, uint32_t> as Counter0;
		interface Timer<TMilli> as Timer0;

		//interface Get<button_state_t>;
		//interface Notify<button_state_t>;

	}
}

implementation{
	uint32_t testN = 10;
	uint32_t lastDisco = 0;
	uint32_t counter_reset_value = 30;
	uint32_t countdown = 0;
	uint16_t ButtonPressCounter = 0;

	uint32_t test_cur = 0;

	uint16_t MprimeIDX[] = {149,100,100,50,50,50,125,100,25,25};
	uint16_t SprimeIDX[] = {149,148,100,146,100,50,125,125,25,149};

	event void Notify.notify(button_state_t value)
	{
		if(value == BUTTON_PRESSED && ButtonPressCounter == 0)
		{
			call Disco.setBeaconMode(TRUE);
			call Disco.setNodeClass(TOS_NODE_ID);
			call Disco.setDutyCycleIndex(MprimeIDX[0],rand());
			lastDisco = call Counter0.get();
		}
		ButtonPressCounter++;
	}

	event error_t Disco.fetchPayload(DiscoMsg *msg,void *buf, uint8_t *len)
	{
		uint16_t p1,p2;

		testMsg newMsg;
		uint32_t nowDisco = call Counter0.get();
		call Disco.getPrimePair(&p1,&p2);


		printf("%lu,%lu,",countdown,test_cur);
		printf("%u,%u,",p1,p2);
		printf("%u,%u,",msg->prime1,msg->prime2);

		printf("%lu\r\n",nowDisco-lastDisco);

		lastDisco = nowDisco;
		




		if(countdown == 0)
		{
			countdown=counter_reset_value;
			test_cur++;
		}

		if(test_cur >= testN)
			return FAIL;

		
		if(test_cur == testN && countdown == 0)
		{
			call Leds.led2On();
			newMsg.next_prim_pair_idx = SprimeIDX[0];
		}
		else
		{
			call Disco.setDutyCycleIndex(MprimeIDX[test_cur],rand());
			newMsg.next_prim_pair_idx = SprimeIDX[test_cur];

		}
			memcpy(buf, &newMsg,sizeof(testMsg));
			*len = sizeof(testMsg);

		call Leds.led0Toggle();

		countdown--;
		return SUCCESS;
	}

	event void Disco.received(DiscoMsg *msg, void *buf, uint8_t len){

	}

	event void Boot.booted(){
		call Leds.led0Off();
		call Leds.led2Off();

		call Leds.led1Off();
		//call Disco.setBeaconMode(TRUE);
		call Disco.setNodeClass(TOS_NODE_ID);
		//call Disco.setDutyCycleIndex(MprimeIDX[0],rand());
		
		if(call Notify.enable()==SUCCESS)
		{
			call Leds.led1On();
		}
		srand(TOS_NODE_ID);
		call Timer0.startOneShot(15000);
		//printf("Boot done\r\n");
		
		//lastDisco = call Counter0.get();

	}

	async event void Counter0.overflow(){
		// TODO Auto-generated method stub
	}

	/* event void Notify.notify(button_state_t val){
		printf("bob\r\n");
		//call Leds.led0Toggle();
		//call Notify.enable();
		if(val==BUTTON_PRESSED)
		{
			call Leds.led0Off();
			call Leds.led2Off();
			call Disco.setBeaconMode(TRUE);
			call Disco.setNodeClass(TOS_NODE_ID);
			call Disco.setDutyCycleIndex(MprimeIDX[0],rand());
			call Leds.led1On();
			printf("countdown,testNr,p11,p12,p21,p22,disco(ms)\r\n");
			lastDisco = call Counter0.get();
		}
	//}*/



	event void Timer0.fired(){
		call Leds.led0Off();
		call Leds.led2Off();
		countdown=counter_reset_value;
		call Disco.setBeaconMode(TRUE);
		call Disco.setNodeClass(TOS_NODE_ID);
		call Disco.setDutyCycleIndex(MprimeIDX[0],rand());
		call Leds.led1On();
		printf("countdown,testNr,p11,p12,p21,p22,disco(ms)\r\n");
		printfflush();
		lastDisco = call Counter0.get();
	}
}