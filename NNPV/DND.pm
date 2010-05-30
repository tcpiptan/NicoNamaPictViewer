package NNPV::DND;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Controller;
use Wx::DND;

package NNPV::DND::Image;

use base qw(Wx::FileDropTarget);

sub OnDropFiles {
    my( $self, $x, $y, $files ) = @_;
    
    my $c = NNPV::Controller->instance;
    $c->load_image($files);
    $c->frame->Raise();
    
    return 1;
}

package NNPV::DND::Url;

use base qw(Wx::TextDropTarget);

sub OnDropText {
    my( $self, $x, $y, $data ) = @_;
    
    my $c = NNPV::Controller->instance;
    $c->dialog_url->{text_ctrl_url}->SetValue($data);
    $c->dialog_url->Raise();
    
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
