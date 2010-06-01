#!/usr/bin/perl -w

# ＵＴＦ－８

use Wx::Perl::Packager;
use NNPV::CommonSense;
use NNPV::App;
use Getopt::Long;

my $size;
my $options = GetOptions(
    "size=s" => \$size,
);
my ($width, $height);
if ($size =~ /^(\d+)x(\d+)$/) {
    if ($1 > 0 and $2 > 0) {
        $width  = $1;
        $height = $2;
    }
}

NNPV::App->run( +{ width => $width, height => $height } )->app->MainLoop;

__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
