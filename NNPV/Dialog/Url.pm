package NNPV::Dialog::Url;

# ＵＴＦ－８

use NNPV::CommonSense;
use base qw(NNPV::Dialog::_Url);

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    
    $self->{text_ctrl_url}->SetDropTarget( NNPV::DND::Url->new );
    
    $self;
}
sub text_ctrl_url {
    my $self = shift;
    $self->{text_ctrl_url}->SetValue(@_) if @_;
    $self->{text_ctrl_url}->GetValue;
}

1;
