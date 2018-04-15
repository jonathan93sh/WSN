#ifndef DISCO_H
#define DISCO_H
enum{
	AM_RADIO = 6,
	TSLOTms = 25
};

 
 typedef nx_struct DiscoMsg {
 	nx_uint16_t nodeid;
 	nx_uint16_t counter;
 	nx_uint16_t timeslot;
 	nx_uint16_t prime1;
 	nx_uint16_t prime2;
 } DiscoMsg;



static const uint16_t primes[] = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59, \
 61,67,71,73,79,83,89,97,101,103,107,109,113,127,\
 131,137,139,149,151,157,163,167,173,179,181,191,\
 193,197,199,211,223,227,229,233,239,241,251,257,\
 263,269,271}; // from A000040
 static const uint8_t primesN = 58;
 
 static const float TH = 0.5f;
 
 error_t getPrimePairBalanceIDUnique(uint16_t ID, float DC, uint16_t* p1, uint16_t* p2, float *realDC)
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
 	
 	*realDC = (1/(*p1*2)) + (1/(*p2*2));
 	
 	return failed;
 	
 }
#endif /* DISCO_H */
