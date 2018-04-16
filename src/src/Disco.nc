interface Disco{
	// Request a duty cycle between 0 and 100 pct
	command uint8_t setDutyCicle(uint8_t dutycycle);
	command uint8_t getDutyCycle();
	
	// Set the node class to reduce inter-class latency
	command error_t setNodeClass(uint8_t classid);
	command uint8_t getNodeClass();
	
	// Select beacon-and-listen or listen-only mode
	command error_t setBeaconMode(bool beacon);
	command bool getBeaconMode();
	
	// Request, event, callback for app-specific payload
	command error_t requestBroadcast();
	event error_t fetchPayload(void *buf, uint8_t *len);
	event message_t received(message_t* msg, void* buf, uint8_t len,uint16_t nodeid);
}