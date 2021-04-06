/**
 *  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
 *
 *  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
 *  Copyright © 2021 The Open Wireless Link Project
 *
 *  SPDX-License-Identifier: MIT
 */

#include <stdint.h>
#include <string.h>

#include <blessed/bdaddr.h>
#include <blessed/evtloop.h>

#include "ll.h"

#define ADV_INTERVAL			2000000	/* 2 s */

/* don't make `const` so we can replace key in compiled binary image */
static char public_key[28] = "OFFLINEFINDINGPUBLICKEYHERE!";

static bdaddr_t addr = {
	{ 0xFF, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF },
	BDADDR_TYPE_RANDOM
};

static uint8_t offline_finding_adv_template[] = {
	0x1e, /* Length (30) */
	0xff, /* Manufacturer Specific Data (type 0xff) */
	0x4c, 0x00, /* Company ID (Apple) */
	0x12, 0x19, /* Offline Finding type and length */
	0x00, /* State */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, /* First two bits */
	0x00, /* Hint (0x00) */
};

void set_addr_from_key() {
	/* copy first 6 bytes */
	/* BLESSED seems to reorder address bytes, so we copy them in reverse order */
	addr.addr[5] = public_key[0] | 0b11000000;
	addr.addr[4] = public_key[1];
	addr.addr[3] = public_key[2];
	addr.addr[2] = public_key[3];
	addr.addr[1] = public_key[4];
	addr.addr[0] = public_key[5];
}

void fill_adv_template_from_key() {
	/* copy last 22 bytes */
	memcpy(&offline_finding_adv_template[7], &public_key[6], 22);
	/* append two bits of public key */
	offline_finding_adv_template[29] = public_key[0] >> 6;
}

int main(void) {
	set_addr_from_key();
	fill_adv_template_from_key();

	ll_init(&addr);
	ll_set_advertising_data(offline_finding_adv_template, sizeof(offline_finding_adv_template));
	ll_advertise_start(LL_PDU_ADV_NONCONN_IND, ADV_INTERVAL, LL_ADV_CH_ALL);

	evt_loop_run();

	return 0;
}
