#ifndef FRIEND_DETECTOR_H
#define FRIEND_DETECTOR_H

enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 1000
};

typedef nx_struct friendDetectorMsg {
	nx_uint16_t nodeid;
} friendDetectorMsg;

#endif /* FRIEND_DETECTOR_H */
