#include <memory.h>
#include "ble_dfu.h"
#include "nrf_sdh.h"
#include "MicroBit.h"

#define microbit_ble_CONN_CFG_TAG 1
#define ADV_INTERVAL							2000

static uint8_t m_adv_handle    = BLE_GAP_ADV_SET_HANDLE_NOT_SET;
static char public_key[28] = {'O', 'F', 'F', 'L', 'I', 'N', 'E', 'F', 'I', 'N', 'D', 'I', 'N', 'G', 'P', 'U', 'B', 'L', 'I', 'C', 'K', 'E', 'Y', 'H', 'E', 'R', 'E', '!'};
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

void fill_adv_template_from_key() {
	/* copy last 22 bytes */
	memcpy(&offline_finding_adv_template[7], &public_key[6], 22);
	/* append two bits of public key */
	offline_finding_adv_template[29] = public_key[0] >> 6;
}

MicroBit uBit;

int main() {
    nrf_sdh_enable_request();
    uint32_t ram_start = 0;
    nrf_sdh_ble_default_cfg_set(microbit_ble_CONN_CFG_TAG, &ram_start);
    nrf_sdh_ble_enable(&ram_start);

    ble_gap_addr_t p_addrset;
    p_addrset.addr_id_peer = 1;
    p_addrset.addr_type = BLE_GAP_ADDR_TYPE_RANDOM_STATIC;
    p_addrset.addr[5] = public_key[0] | 0b11000000;
    p_addrset.addr[4] = public_key[1];
    p_addrset.addr[3] = public_key[2];
    p_addrset.addr[2] = public_key[3];
    p_addrset.addr[1] = public_key[4];
    p_addrset.addr[0] = public_key[5];
		sd_ble_gap_addr_set(&p_addrset);

  	fill_adv_template_from_key();

		ble_gap_adv_params_t gap_adv_params;
    memset(&gap_adv_params, 0, sizeof( gap_adv_params));
    gap_adv_params.properties.type = BLE_GAP_ADV_TYPE_NONCONNECTABLE_SCANNABLE_UNDIRECTED;
    gap_adv_params.interval = (1000 * ADV_INTERVAL) / 625; // 625 us units
    if (gap_adv_params.interval < BLE_GAP_ADV_INTERVAL_MIN) gap_adv_params.interval = BLE_GAP_ADV_INTERVAL_MIN;
    if (gap_adv_params.interval > BLE_GAP_ADV_INTERVAL_MAX) gap_adv_params.interval = BLE_GAP_ADV_INTERVAL_MAX;
    gap_adv_params.duration = 0; //10 ms units
    gap_adv_params.filter_policy = BLE_GAP_ADV_FP_ANY;
    gap_adv_params.primary_phy = BLE_GAP_PHY_1MBPS;

    ble_gap_adv_data_t  gap_adv_data;
    memset( &gap_adv_data, 0, sizeof( gap_adv_data));
    gap_adv_data.adv_data.p_data = offline_finding_adv_template;
    gap_adv_data.adv_data.len = BLE_GAP_ADV_SET_DATA_SIZE_MAX;

		sd_ble_gap_adv_set_configure(&m_adv_handle, &gap_adv_data, &gap_adv_params);
		sd_ble_gap_adv_start( m_adv_handle, microbit_ble_CONN_CFG_TAG);

    while(1) {
      uBit.display.scroll("OpenHaystack");
    }
  	return 0;
}
