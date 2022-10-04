# SUSE's openQA tests
#
# Copyright SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Confirm system reboot by pressing "OK" button
#
# Maintainer: QA SLE YaST team <qa-sle-yast@suse.de>

use base 'y2_installbase';
use strict;
use warnings;
use testapi;

sub run {
    eject_cd();
    $testapi::distri->get_performing_installation()->confirm_reboot();
}

1;
