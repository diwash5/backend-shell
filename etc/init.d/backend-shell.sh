#!/bin/sh /etc/rc.common

START=60

USE_PROCD=1
PROG=/etc/userdata/bandwidthd-shell.sh
NICELVL=19

start_service() {
        procd_open_instance
        procd_set_param stderr 1
        procd_set_param command "$PROG"
        procd_set_param nice "$NICELVL"
        procd_close_instance
}
