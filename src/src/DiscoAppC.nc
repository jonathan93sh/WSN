#include <Timer.h>
#include "Disco.h"

configuration DiscoAppC{
}
implementation{
	components MainC;
	components LedsC;
	components friendDetectorC as App;
	components DiscoC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	
	
	
	DiscoC.Timer0 -> Timer0;
	DiscoC.Timer1 -> Timer1;
	DiscoC.Packet->AMSenderC;
	DiscoC.AMPacket->AMSenderC;
	DiscoC.AMSend->AMSenderC;
	DiscoC.AMControl->ActiveMessageC;
	
}