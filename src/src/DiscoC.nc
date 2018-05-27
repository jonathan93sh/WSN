#include <Timer.h>
#include "Disco.h"

module DiscoC{
	provides {
		interface Disco;
		}

	uses {
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;
		interface Timer<TMilli> as Timer2_retransmit;
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
	uint16_t timeout = 0;
	bool beaconEn = FALSE;
	bool busy = FALSE;
	uint16_t connectNodeID = -1; 
	nx_uint8_t packetBuffer[100];
	size_t PacketSize = 0;
	uint8_t retry_counter = 0;
	//TOS_NODE_ID
	//prototypes
	void transmit_done();
	void transmit();
	void transmitPacket(void *payload, uint8_t len);	
	void transmitBeacon();
	void transmitRequst();
	void transmitACK();
	
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
		counter=shift;
		call Timer0.startPeriodic(TSLOTms);
		return 0;
	}
	
	command void Disco.getPrimePair(uint16_t * p1, uint16_t * p2){
		*p1 = prime1;
		*p2 = prime2;
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
		beaconEn = beacon;
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
	bool eop = FALSE;	

	event void Timer0.fired(){
		//printf("Timer0 Trig\r\n");
		if(!busy)
		{
			if(counter%prime1==0 || counter%prime2==0)
			{
				timeout = 0;
				call Timer1.stop();
				//call Timer1.startOneShot(TSLOTms);//-T_TIMEOUT_ms
				call AMControl.start();
				eop = FALSE;
			}
			else if((counter-1)%prime1==0 || (counter-1)%prime2==0)
			{
				if(beaconEn)
				{
					transmitBeacon();
				}
				else if(retry_counter == 0)
				{
					call AMControl.stop();
				}
				//
				eop = TRUE;
			}
		}
		counter++;
	}
	

	
	event void Timer1.fired(){
		call AMControl.stop();
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
		printf("Received message\r\n");
		
		
		if(getDiscoMsg(payload,&msgPtr,&msgPayload,len,&payload_len) == SUCCESS)
		{
			

			switch(msgPtr->type)
			{
				case T_ACK:
					printf("ACK\r\n");
					transmit_done();
					break;
				case T_BEACON:
					transmit_done();
					connectNodeID = msgPtr->nodeid;
					signal Disco.received(msgPtr, 0, 0);
					//connectNodeID = -1;
					break;
				case T_PAYLOAD:
					transmit_done();
					transmitACK();
					signal Disco.received(msgPtr, msgPayload, payload_len);
					break;
				case T_REQUEST:
					printf("ID:%u Got a request for ID: %u\r\n",ID ,(msgPayload[0]<<8)|msgPayload[1]);
					if(retry_counter != 0)
					{
						printf("allready trying to send payload\r\n");
					}
					else if((msgPayload[0]<<8)|msgPayload[1] == ID)
					{
						transmit_done();
						printf("ID ok\r\n");
						if(signal Disco.fetchPayload(msgPtr,packetBuffer, &Rlen) == SUCCESS)
						{
							printf("get ready to send payload\r\n");
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
	

	
	event void Timer2_retransmit.fired(){
		printf("retransmit timeout\r\n");
		transmit();
	}
	
	void transmit_done()
	{
		call Timer2_retransmit.stop();
		PacketSize = 0;
		retry_counter = 0;
		if(eop)
		{
			call Timer1.startOneShot(T_TIMEOUT_ms);
		}
	}
	
	void transmit()
	{
		//printf("transmit message\r\n");
		call Timer1.stop();
		if(!busy)
		{
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, PacketSize) == SUCCESS) {
				busy = TRUE;
			}
			
			
		}
		if(retry_counter != 0)
		{
			call Timer2_retransmit.startOneShot(T_TIMEOUT_ms);
			retry_counter--;
		}
		else if(eop)
		{
			call Timer1.startOneShot(T_TIMEOUT_ms);
		}
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
			
			PacketSize = sizeof(DiscoMsg);
			retry_counter = 0;
			transmit();
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
			
			PacketSize = sizeof(DiscoMsg)+len;
			retry_counter = RETRYS;
			transmit();
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

			createDiscoMsg((DiscoMsg*)DiscoPacket,ID,counter,TSLOTms,prime1,prime2,T_REQUEST,sizeof(nx_uint16_t));//create beacon msg
			//printf("to ID in package: %u\r\n", (payload[0]<<8)|payload[1]);
			PacketSize = sizeof(DiscoMsg)+sizeof(nx_uint16_t);
			retry_counter = RETRYS;
			transmit();
		}	
	}
	
	void transmitACK()
	{
		if(!busy)
		{

			uint8_t * DiscoPacket = (uint8_t *)(call Packet.getPayload(&pkt, sizeof(DiscoMsg)));
			//printf("Transmit request connectNodeID: %u\r\n", connectNodeID);


			createDiscoMsg((DiscoMsg*)DiscoPacket,ID,counter,TSLOTms,prime1,prime2,T_ACK,0);//create beacon msg
			//printf("to ID in package: %u\r\n", (payload[0]<<8)|payload[1]);
			
			PacketSize = sizeof(DiscoMsg);
			retry_counter = 0;
			transmit();
		}	
	}
	
	






}