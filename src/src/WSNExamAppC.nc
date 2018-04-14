#include <Timer.h>
#include "WSNExam.h"

configuration WSNExamAppC{
}
implementation{
   components MainC;
   components LedsC;
   components WSNExamC as App;
   components new TimerMilliC() as Timer0;
   
   components ActiveMessageC;
   components new AMSenderC(AM_RADIO);
   
   components new AMReceiverC(AM_RADIO);
   
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.Timer0 -> Timer0;
   
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   
   App.Receive -> AMReceiverC;
}