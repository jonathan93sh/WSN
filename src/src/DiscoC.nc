#include <Timer.h>
#include "Disco.h"

module DiscoC{
	provides {
		interface Disco;
		}

	uses {
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;
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
	uint32_t counter = 0;
	float DC = 0;
	uint16_t ID = 0;
	bool beaconEn = FALSE;
	bool busy = FALSE;
	uint16_t connectNodeID = -1; 
	nx_uint8_t packetBuffer[100];
	//TOS_NODE_ID
	//prototypes
	void transmitPacket(void *payload, uint8_t len);	
	void transmitBeacon();
	void transmitRequst();
	
// Disco - interface - start -------------------------------
	command float Disco.setDutyCycle(float dutycycle, uint32_t shift){
		getPrimePair(dutycycle, &prime1, &prime2, &DC);
		//getPrimePairBalanceIDUnique(ID, dutycycle, &prime1, &prime2, &DC);
		counter=shift;
		call Timer0.startPeriodic(TSLOTms);
		printf("ID: %u, set dutycycle (wanted/real) 1/1000: (%u/%u), prime1: %u, prime2: %u", ID, (uint16_t)(dutycycle*1000), (uint16_t)(DC*1000), prime1,prime2);
		return DC;
	}

	command float Disco.getDutyCycle(){
		return DC;
	}
	
	command float Disco.setDutyCycleIndex(uint16_t dutycycleIdx, uint32_t shift){
		if(dutycycleIdx >= PRIMEPAIRS_LENGTH)
			return 0;
		prime1 = lutPrime1[dutycycleIdx];
		prime2 = lutPrime2[dutycycleIdx];
		DC = (float)lutDC[dutycycleIdx] / 10000.0f;
		return 0;
	}

	command uint16_t Disco.getMaxDutyCycleIndex(){
		return PRIMEPAIRS_LENGTH;
	}
	
	command error_t Disco.setNodeClass(uint16_t classid){
		ID=classid;
		return FALSE;
	}

	command uint16_t Disco.getNodeClass(){
		return ID;
	}

	command error_t Disco.setBeaconMode(bool beacon){
		beaconEn = TRUE;
		return SUCCESS;
	}

	command bool Disco.getBeaconMode(){
		return beaconEn;
	}

	command error_t Disco.requestBroadcast(){
		if(connectNodeID == (uint16_t)-1)
			return FAIL;
		
		transmitRequst();
			
		return SUCCESS;
	}
	// Disco - interface - end -------------------------------
	

	event void Timer0.fired(){
		//printf("Timer0 Trig\r\n");
		if(!busy)
		{
			if(counter%prime1==0 || counter%prime2==0)
			{
				call Timer1.startOneShot(TSLOTms-T_TIMEOUT_ms);
				call AMControl.start();
			}
			else
			{
				call AMControl.stop();
			}
		}
		counter++;
	}
	
	event void Timer1.fired(){
		//printf("Timer1 Trig\r\n");
		transmitBeacon();
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		busy = FALSE;
	}

	event void AMControl.startDone(error_t error){
		if(error==SUCCESS)
			transmitBeacon();
	}

	event void AMControl.stopDone(error_t error){
		
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		DiscoMsg *msgPtr;
		uint8_t *msgPayload;
		uint8_t payload_len;
		uint8_t Rlen;
		//printf("Received message\r\n");
		
		
		if(getDiscoMsg(payload,&msgPtr,&msgPayload,len,&payload_len) == SUCCESS)
		{
			switch(msgPtr->type)
			{
				case T_BEACON:
					connectNodeID = msgPtr->nodeid;
					signal Disco.received(msg, 0, 0,msgPtr->nodeid);
					//connectNodeID = -1;
					break;
				case T_PAYLOAD:
					signal Disco.received(msg, msgPayload, payload_len,msgPtr->nodeid);
					break;
				case T_REQUEST:
					//printf("ID:%u Got a request for ID: %u\r\n",ID ,(msgPayload[0]<<8)|msgPayload[1]);
					if((msgPayload[0]<<8)|msgPayload[1] == ID)
					{
						//printf("ID ok\r\n");
						if(signal Disco.fetchPayload(packetBuffer, &Rlen, msgPtr->nodeid) == SUCCESS)
						{
							//printf("get ready to send payload\r\n");
							transmitPacket(packetBuffer,Rlen);
						}
					}
					else
					{
						printf("wrong ID\r\n");	
					}
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
		DiscoMsg * dmpkt;
		if(!busy && beaconEn)
		{
			//printf("send Beacon\r\n");
			dmpkt = (DiscoMsg *)(call Packet.getPayload(&pkt, sizeof(DiscoMsg)));
			createDiscoMsg(dmpkt,ID,counter,TSLOTms,prime1,prime2,T_BEACON,0);//create beacon msg
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
	
	void transmitPacket(void *payload, uint8_t len)
	{
		uint8_t * DiscoPacket;
		if(!busy)
		{

			DiscoPacket = (uint8_t *)(call Packet.getPayload(&pkt, (uint8_t)sizeof(DiscoMsg)+len));
			
			
			
			memcpy(DiscoPacket+sizeof(DiscoMsg),payload,len);
			
			createDiscoMsg((DiscoMsg*)DiscoPacket,ID,counter,TSLOTms,prime1,prime2,T_PAYLOAD,len);
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)+len) == SUCCESS) {
				busy = TRUE;
			}
		}		
	}
	
	void transmitRequst()
	{
		if(!busy)
		{
			uint8_t *payload;
			uint8_t * DiscoPacket = (uint8_t *)(call Packet.getPayload(&pkt, sizeof(DiscoMsg)+sizeof(nx_uint16_t)));
			//printf("Transmit request connectNodeID: %u\r\n", connectNodeID);
			payload = ((uint8_t *)DiscoPacket+sizeof(DiscoMsg));
			payload[0] = connectNodeID>>8;
			payload[1] = connectNodeID&0xFF;
			
			
			
			//memcpy(DiscoPacket+sizeof(DiscoMsg),&connectNodeID,sizeof(nx_uint16_t));
			
			
			createDiscoMsg((DiscoMsg*)DiscoPacket,ID,counter,TSLOTms,prime1,prime2,T_REQUEST,sizeof(nx_uint16_t));//create beacon msg
			//printf("to ID in package: %u\r\n", (payload[0]<<8)|payload[1]);
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)+sizeof(nx_uint16_t)) == SUCCESS) {
				busy = TRUE;
			}
		}	
	}
	
	
	
	




}