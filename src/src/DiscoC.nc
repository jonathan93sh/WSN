#include <Timer.h>
#include "Disco.nc"
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
	uint16_t counter = 0;
	uint8_t DC = 0;
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
		if(!busy)
		{
			if(counter%prime1 || counter%prime2)
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
		void *msgPayload;
		uint8_t payload_len;
		uint8_t Rlen;
		
		
		if(getDiscoMsg(payload,&msgPtr,&msgPayload,&payload_len) == SUCCESS)
		{
			switch(msgPtr->type)
			{
				case T_BEACON:
					connectNodeID = msgPtr->nodeid;
					signal Disco.received(msg, 0, 0,msgPtr->nodeid);
					connectNodeID = -1;
					break;
				case T_PAYLOAD:
					signal Disco.received(msg, msgPayload, payload_len,msgPtr->nodeid);
					break;
				case T_REQUEST:
					if( *(nx_uint16_t*)msgPayload == ID)
					{
						if(signal Disco.fetchPayload(packetBuffer, &Rlen) == SUCCESS)
						{
							transmitPacket(packetBuffer,Rlen);
						}
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
		if(!busy && beaconEn)
		{
			DiscoMsg * dmpkt = (DiscoMsg *)(call Packet.getPayload(&pkt, sizeof(DiscoMsg)));
			createDiscoMsg(dmpkt,ID,counter,TSLOTms,prime1,prime2,T_BEACON,0);//create beacon msg
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
	
	void transmitPacket(void *payload, uint8_t len)
	{
		if(!busy)
		{

			uint8_t * DiscoPacket = (uint8_t *)(call Packet.getPayload(&pkt, (uint8_t)sizeof(DiscoMsg)+len));
			
			memcpy(pkt+sizeof(DiscoMsg),payload,len);
			
			createDiscoMsg((DiscoMsg*)DiscoPacket,ID,counter,TSLOTms,prime1,prime2,T_PAYLOAD,len);
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}		
	}
	
	void transmitRequst()
	{
		if(!busy)
		{
			uint8_t * DiscoPacket = (uint8_t *)(call Packet.getPayload(&pkt, sizeof(DiscoMsg)+sizeof(nx_uint16_t)));
			
			memcpy(DiscoPacket+sizeof(DiscoMsg),&connectNodeID,sizeof(nx_uint16_t));
			createDiscoMsg((DiscoMsg*)DiscoPacket,ID,counter,TSLOTms,prime1,prime2,T_REQUEST,0);//create beacon msg
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DiscoMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}	
	}
	
	
	
	


}