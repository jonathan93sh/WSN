#include <message.h>

interface Disco{
	// Request a duty cycle between 0 and 100 pct

	command float setDutyCycle(float dutycycle, uint32_t shift);
	command float setDutyCycleIndex(uint16_t dutycycleIdx, uint32_t shift);
	command uint16_t getMaxDutyCycleIndex();
	command float getDutyCycle();
	
	// Set the node class to reduce inter-class latency
	command error_t setNodeClass(uint16_t classid);
	command uint16_t getNodeClass();
	
	// Select beacon-and-listen or listen-only mode
	command error_t setBeaconMode(bool beacon);
	command bool getBeaconMode();
	
	// Request, event, callback for app-specific payload
	command error_t requestBroadcast();
	event error_t fetchPayload(void *buf, uint8_t *len, uint16_t nodeid);
	event message_t received(message_t* msg, void* buf, uint8_t len,uint16_t nodeid);
}