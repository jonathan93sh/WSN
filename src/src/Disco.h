#ifndef DISCO_H
#define DISCO_H
enum{
	AM_RADIO = 6,
	TSLOTms = 35,
	T_TIMEOUT_ms = 5
};

enum DiscoMsgTypes{
	T_BEACON = 0,
	T_REQUEST = 1,
	T_PAYLOAD = 2
};

 // [DiscoMsg| Payload ]
 typedef nx_struct DiscoMsg {
 	nx_uint16_t nodeid;
 	nx_uint16_t counter;
 	nx_uint16_t timeslot;
 	nx_uint16_t prime1;
 	nx_uint16_t prime2;
 	nx_uint8_t type;
 	nx_uint8_t payload_len; //len=0 is just a beacon
 	nx_uint8_t checksum;
 } DiscoMsg;
 
 typedef nx_struct PrimePair{
 	nx_uint16_t prime1;
 	nx_uint16_t prime2;
 } PrimePair;

uint8_t calcCheckSumMsg(DiscoMsg* this);



void createDiscoMsg(DiscoMsg* this,uint16_t nodeid,uint16_t counter, uint16_t timeslot, uint16_t prime1, uint16_t prime2, uint8_t type, uint8_t payload_len)
{
	this->nodeid = nodeid;
	this->counter = counter;
	this->timeslot = timeslot;
	this->prime1 = prime1;
	this->prime2 = prime2;
	this->type = type;
	this->payload_len = payload_len;
	this->checksum = calcCheckSumMsg(this);
}

uint8_t calcCheckSumMsg(DiscoMsg* this)
{
	uint8_t i;
	uint8_t checksum = 0;
	for(i=0;i<sizeof(DiscoMsg)-1;i++)
		checksum+=*(((uint8_t *)this)+i);
	return checksum;
}

error_t getDiscoMsg(void *payload,DiscoMsg **msgPtr,void **msgPayload,uint8_t len,uint8_t *payloadlen)
{
	DiscoMsg * dmHeader;
	*msgPtr = NULL;
	*msgPayload = NULL;
	
	*payloadlen = 0;
	
	
	if(len <= sizeof(DiscoMsg)-1) //must have received a message from another protocol then disco.
	{
		printf("wrong format to small: (%u/%u)\r\n",len,sizeof(DiscoMsg)-1);	
		return FAIL;
	}
			
		
	dmHeader = (DiscoMsg *)payload;
	
	/*printf("Disco msg: nodeid %u, counter %u, timeslot %u, prime1 %u, prime2 %u, type %u, payload len %u, checksum %u\r\n", 
		dmHeader->nodeid,
		dmHeader->counter,
		dmHeader->timeslot,
		dmHeader->prime1,
		dmHeader->prime2,
		dmHeader->type,
		dmHeader->payload_len,
		dmHeader->checksum);*/

	if(dmHeader->checksum != calcCheckSumMsg(dmHeader))
	{
		printf("CRC fail (calc/msg):(%u/%u)\r\n",calcCheckSumMsg(dmHeader),dmHeader->checksum);
		return FAIL;
	}
		
	
	if(dmHeader->payload_len != len-sizeof(DiscoMsg))
	{
		printf("Payload len wrong size: (%u/%u)\r\n",len-sizeof(DiscoMsg),dmHeader->payload_len);
		return FAIL;
	}
		
	
	if(dmHeader->type == T_REQUEST && dmHeader->payload_len != sizeof(uint16_t))
	{
		printf("Payload len wrong size: (%u/%u), then request type max: %u\r\n",len-sizeof(DiscoMsg),dmHeader->payload_len, sizeof(uint16_t));
		return FAIL;
	}
		
	
	*msgPtr = dmHeader;
		
	if(dmHeader->payload_len != 0)
	{
		*msgPayload = ((uint8_t *)payload+sizeof(DiscoMsg));
		*payloadlen = dmHeader->payload_len;
	}
	
	return SUCCESS;
}


static const uint16_t primes[] = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59, \
 61,67,71,73,79,83,89,97,101,103,107,109,113,127,\
 131,137,139,149,151,157,163,167,173,179,181,191,\
 193,197,199,211,223,227,229,233,239,241,251,257,\
 263,269,271}; // from A000040
 static const uint8_t primesN = 58;
 
 static const float TH = 0.5f;
 
 // ca = 0.2,0.5,1,2,3,4,5,10,20,30,40,50,100%
 static const PrimePair pairs1[] = {{1003,997},{400,401},{203,197},{97,103},{67,66},{49,51},{43,37},{21,19},{9,11},{5,7},{4,5},{4,3},{1,1}};
 
static const PrimePair pairs2[] = {{991,1009},{403,397},{201,199},{99,101},{65,68},{48,53},{31,47},{17,23},{7,13},{3,11},{7,3},{3,5},{1,1}};
 
 //ca 5%
 static const PrimePair asyncpairs1[] = {{23,151},{24,121}};
  static const PrimePair asyncpairs2[] = {{21,421},{25,101}};
 
 error_t getPrimePairBalanceIDUnique(uint16_t ID, uint8_t DC, uint16_t* p1, uint16_t* p2, uint8_t *realDC)
 {
 	
 	
 	//*realDC=100;
 	*p1 = 21;
 	*p2 = 421;
 	
 	*realDC = 100/(*p1)+100/(*p2);
 	
 	return SUCCESS;
 }
 
 
 error_t getPrimePairBalanceIDUnique_old(uint16_t ID, uint8_t DC, uint16_t* p1, uint16_t* p2, uint8_t *realDC)
 {
 	
 	uint16_t randomPrime1 = primes[ID%primesN];
 	uint16_t randomPrime2 = primes[(ID+1)%primesN];
 	uint16_t p_hat = (uint16_t)((1.0/DC)/2.0);
 	int i;
 	uint16_t primeTmp;
 	bool failed = TRUE;
 	
 	for(i = 0; i < primesN; i++)
 	{
 		primeTmp = primes[(i*randomPrime1+ID) % primesN];
 		if(p_hat*(1.0-TH) <= primeTmp && primeTmp <= p_hat*(1.0-TH))
 		{
 			*p1 = primeTmp;
 			failed = FALSE;
 			break;
 		}
 	}
 	if(!failed)
 	{
 		for(i = 0; i < primesN; i++)
	 	{
	 		primeTmp = primes[(i*randomPrime2+ID) % primesN];
	 		if(primeTmp==*p1)
	 			continue;
	 		if(p_hat*(1.0-TH) <= primeTmp && primeTmp <= p_hat*(1.0-TH))
	 		{
	 			*p2 = primeTmp;
	 			failed = FALSE;
	 			break;
	 		}
	 	}
 	}
 	
 	
 	if(failed) // get primes even if the unique primes generator has failed.
 	{
 		for(i = 1; i < primesN; i++)
 		{
 			*p1 = primes[i];
 			*p2 = primes[i-1];
 			if(p_hat*(1.0-TH) <= *p1)
 				break;
 		}	
 	}
 	
 	*realDC = (uint8_t)((1/(*p1*2)) + (1/(*p2*2)));
 	
 	return failed;
 	
 }
#endif /* DISCO_H */
