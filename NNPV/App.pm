package NNPV::App;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use NNPV::Controller;

sub run {
    my $class = shift;
    my $args = shift;
    
    $NNPV::IMAGE_WIDTH  = $args->{width}  if $args->{width}  > 0;
    $NNPV::IMAGE_HEIGHT = $args->{height} if $args->{height} > 0;
    
    my $c = NNPV::Controller->instance;
    
    $c->init;
    $c->init_image;
    $c->init_store;
    $c->init_app;
    $c->init_config;
    $c->init_frame;
    
    $c->run;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
