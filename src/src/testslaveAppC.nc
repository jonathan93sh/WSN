#include <Timer.h>
#include "Disco.h"

configuration testslaveAppC{
}
implementation{
	components MainC;
	components LedsC;
	components testslaveC as App;
	components DiscoC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	
	//components CounterMilli32C as Counter0;
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	components new AMReceiverC(AM_RADIO);

	DiscoC.Timer0 -> Timer0;
	DiscoC.Timer1 -> Timer1;
	DiscoC.Timer2_retransmit -> Timer2;
	DiscoC.Packet->AMSenderC;
	DiscoC.AMPacket->AMSenderC;
	DiscoC.AMSend->AMSenderC;
	DiscoC.AMControl->ActiveMessageC;
	DiscoC.Receive -> AMReceiverC;
	
	App.Boot -> MainC;
	App.Disco -> DiscoC;
	App.Leds -> LedsC;	
}