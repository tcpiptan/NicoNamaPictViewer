package NNPV::Dialog::Url;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Controller;
use Wx qw(:everything);
use base qw(NNPV::Dialog::_Url);
use Wx::Event qw(:everything);

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    
    $self->SetClientSize([$NNPV::IMAGE_WIDTH,32]);
    $self->{text_ctrl_url}->SetDropTarget( NNPV::DND::Url->new );
    
    EVT_TEXT_ENTER($self, $self->{text_ctrl_url}, \&on_enter);
    
    $self;
}

sub on_enter {
    my ($self, $event) = @_;
    $self->EndModal(wxID_OK);
}

sub text_ctrl_url {
    my $self = shift;
    $self->{text_ctrl_url}->SetValue(@_) if @_;
    $self->{text_ctrl_url}->GetValue;
}

1;
