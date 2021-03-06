# SUSE's openQA tests
#
# Copyright © 2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Package: container-diff
# Summary: Print and save diffs between two cotaniners using container-diff tool
# Maintainer: Pavel Dostál <pdostal@suse.cz>

use base 'consoletest';
use testapi;
use utils;
use strict;
use warnings;
use containers::common;
use containers::container_images;
use suse_container_urls 'get_suse_container_urls';

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;

    install_docker_when_needed();
    zypper_call("install container-diff") if (script_run("which container-diff") != 0);

    my ($image_names, $stable_names) = get_suse_container_urls();

    # container-diff
    for my $i (0 .. $#$image_names) {
        my $image_file = $image_names->[$i] =~ s/\/|:/-/gr;
        assert_script_run("docker pull $image_names->[$i]",  360);
        assert_script_run("docker pull $stable_names->[$i]", 360);
        assert_script_run("container-diff diff daemon://$image_names->[$i] daemon://$stable_names->[$i] --type=rpm --type=file --type=size > /tmp/container-diff-$image_file.txt", 300);
        upload_logs("/tmp/container-diff-$image_file.txt");
    }

    # Clean container
    clean_container_host(runtime => "docker");
}

1;
