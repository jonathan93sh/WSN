#ifndef FRIEND_DETECTOR_H
#define FRIEND_DETECTOR_H

enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 1000
};

typedef nx_struct testMsg_t {
	nx_uint16_t next_prim_pair_idx;
} testMsg;

#endif /* FRIEND_DETECTOR_H */
