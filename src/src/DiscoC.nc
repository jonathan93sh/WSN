#include <Timer.h>
#include "Disco.nc"
#include "Disco.h"

module DiscoC{
	provides {
		interface Disco;
		}

	uses {
		interface Timer<TMilli> as Timer0;
		//interface Timer<TMilli> as Timer1;
		// AM stuf
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;
	}
}
implementation{
	message_t pkt;//default packet header.
	uint16_t prime1,prime2;
	uint16_t counter = 0;
	uint8_t DC = 0;
	uint8_t ID = 0;
	bool beaconEn = FALSE;
	bool busy = FALSE;
	//TOS_NODE_ID
		
	
// Disco - interface - start -------------------------------
	command uint8_t Disco.setDutyCicle(uint8_t dutycycle){
		getPrimePairBalanceIDUnique(ID, dutycycle, &prime1, &prime2, &DC);
		counter=0;
		call Timer0.startPeriodic(TSLOTms);
		return DC;
	}

	command uint8_t Disco.getDutyCycle(){
		return DC;
	}

	command error_t Disco.setNodeClass(uint8_t classid){
		ID=classid;
		return FALSE;
	}

	command uint8_t Disco.getNodeClass(){
		return ID;
	}

	command error_t Disco.setBeaconMode(bool beacon){
		beaconEn = TRUE;
		return FALSE;
	}

	command bool Disco.getBeaconMode(){
		return beaconEn;
	}

	command error_t Disco.requestBroadcast(){
		// TODO Auto-generated method stub
		return TRUE;
	}
	// Disco - interface - end -------------------------------
	

	event void Timer0.fired(){
		if(counter%prime1 || counter%prime2)
		{
			call AMControl.start();
		}
		counter++;
	}


	event void AMSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

	event void AMControl.startDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		DiscoMsg *msgPtr;
		void *msgPayload;
		uint8_t payload_len;
		
		
		if(getDiscoMsg(payload,&msgPtr,&msgPayload,&payload_len) == SUCCESS)
		{
			switch(msgPtr->type)
			{
				case T_BEACON:
				case T_PAYLOAD:
					signal Disco.received(msg, msgPayload, payload_len);
				break;
				case T_REQUEST:
					//signal Disco.fetchPayload(void *buf, uint8_t *len)
				break;
				default:
				break;
			};
			
			
		}
		
		return &pkt;
	}
	//methodes
	void transmitBeacon()
	{
		if(!busy && beaconEn)
		{
			DiscoMsg * dmpkt = (DiscoMsg *)(call Packet.getPayload(&pkt, sizeof(DiscoMsg)));
			createDiscoMsg(dmpkt,ID,counter,TSLOTms,prime1,prime2,T_BEACON,0);//create beacon msg
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
	
	
}