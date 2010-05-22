package NNPV::Dialog::Settings;

# ＵＴＦ－８

use NNPV::CommonSense;
use base qw(NNPV::Dialog::_Settings);

sub slideshow_interval {
    my $self = shift;
    $self->{spin_ctrl_slideshow}->SetValue(@_) if @_;
    $self->{spin_ctrl_slideshow}->GetValue;
}

sub slideshow_shuffle {
    my $self = shift;
    $self->{checkbox_slideshow_shuffle}->SetValue(@_) if @_;
    $self->{checkbox_slideshow_shuffle}->GetValue;
}

1;
