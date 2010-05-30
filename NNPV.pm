package NNPV;

# ＵＴＦ－８

use NNPV::CommonSense;

our $VERSION      = '0.2.0';
our $APPNAME      = 'NicoNamaPictViewer';
our $APPSHORTNAME = 'nnpv';
our $AUTHOR       = 'tcpiptan';
our $EMAIL        = 'ptan@ptan.info';
our $VENDORNAME   = 'tcpiptan';
our $IMAGE_WIDTH  = 512;
our $IMAGE_HEIGHT = 384;
our $EXE          = $APPSHORTNAME . ($^O eq 'MSWin32' ? '.exe' : '');

our $WIN32;
our $PAR;
our $PDK;
BEGIN {
    $WIN32 = ($^O eq 'MSWin32'                ? 1 : 0);
    $PAR   = (defined $INC{"PAR.pm"}          ? 1 : 0);
    $PDK   = (defined $INC{"PerlApp/DATA.pm"} ? 1 : 0);
};

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
