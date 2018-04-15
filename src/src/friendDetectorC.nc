#include "Disco.nc"
#include "friendDetector.h"
module friendDetectorC{
	uses {
		interface Disco;	
	}
}
implementation{

	event message_t Disco.received(message_t *msg, void *buf, uint8_t len){
		friendDetectorMsg * FDmsg = (friendDetectorMsg *)buf;
		
	}

	event error_t Disco.fetchPayload(void *buf, uint8_t *len){
		// TODO Auto-generated method stub
	}
}