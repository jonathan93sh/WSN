module WSNExamC{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
   
   	uses interface Packet;
   	uses interface AMPacket;
   	uses interface AMSend;
   	uses interface SplitControl as AMControl;
   
	uses interface Receive;

	uses interface Disco;

}
implementation{




	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void AMControl.startDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

	event void Timer0.fired(){
		// TODO Auto-generated method stub
	}

	event void Boot.booted(){
		// TODO Auto-generated method stub
	}

	event error_t Disco.fetchPayload(void *buf, uint8_t *len, uint16_t nodeid){
		// TODO Auto-generated method stub
		return FAIL;
	}

	event message_t Disco.received(message_t *msg, void *buf, uint8_t len, uint16_t nodeid){
		// TODO Auto-generated method stub
		return *msg;
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		return msg;
	}
}