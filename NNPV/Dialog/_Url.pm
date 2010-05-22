package NNPV::Dialog::_Url;

# ＵＴＦ－８

use NNPV::CommonSense;
use Wx qw[:everything];
use base qw(Wx::Dialog);

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: NNPV::Dialog::_Url::new

	$style = wxDEFAULT_DIALOG_STYLE|wxSTAY_ON_TOP 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{label_url} = Wx::StaticText->new($self, -1, "URL: ", wxDefaultPosition, wxDefaultSize, );
	$self->{text_ctrl_url} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{button_ok} = Wx::Button->new($self, wxID_OK, "取得");

	$self->__set_properties();
	$self->__do_layout();

# end wxGlade
	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: NNPV::Dialog::_Url::__set_properties

	$self->SetTitle("Webから取得");
	if ($^O eq 'MSWin32') {
		$self->SetSize(Wx::Size->new(520, 64));
		$self->{text_ctrl_url}->SetMinSize(Wx::Size->new(380,20));
	}
	else {
		$self->SetSize(Wx::Size->new(512, 32));
		$self->{text_ctrl_url}->SetMinSize(Wx::Size->new(360,20));
	}
	$self->{text_ctrl_url}->SetFocus();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: NNPV::Dialog::_Url::__do_layout

	$self->{sizer_top} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_top}->Add($self->{label_url}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_top}->Add($self->{text_ctrl_url}, 0, wxALL|wxEXPAND|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_top}->Add($self->{button_ok}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->SetSizer($self->{sizer_top});
	$self->Layout();

# end wxGlade
}

# end of class NNPV::Dialog::_Url

1;
