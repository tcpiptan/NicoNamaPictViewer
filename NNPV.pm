package NNPV;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Controller;

our $DEBUG   = 1;
our $APPNAME = 'NicoNamaPictViewer';
our $VENDORNAME = 'tcpiptan';
our $VERSION = '0.1.0';

sub run {
    my $class = shift;
    
    my $controller = NNPV::Controller->instance;
    
    $controller->init;
    $controller->init_image;
    $controller->init_store;
    $controller->init_app;
    $controller->init_config;
    $controller->init_frame;
    
    $controller->run;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
