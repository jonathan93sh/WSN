#ifndef FRIEND_DETECTOR_H
#define FRIEND_DETECTOR_H

enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 1000
};

typedef nx_struct testMsg_t {
	nx_uint16_t new_prime1;
	nx_uint16_t new_prime2;
} testMsg;

#endif /* FRIEND_DETECTOR_H */
