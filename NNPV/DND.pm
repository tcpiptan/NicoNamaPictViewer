package NNPV::DND;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Controller;
use Wx::DND;

use base qw(Wx::FileDropTarget);

sub new { shift->SUPER::new(@_) }

sub OnDropFiles {
    my( $self, $x, $y, $files ) = @_;
    
    my $controller = NNPV::Controller->instance;
    $controller->load_image($files);
    $controller->frame->Raise();
    
    return 1;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
