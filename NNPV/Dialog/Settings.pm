package NNPV::Dialog::Settings;

# ＵＴＦ－８

use NNPV::CommonSense;
use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(NNPV::Dialog::_Settings);

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    
# ADD SUPER::new
#     my $c = NNPV::Controller->instance;
#     my $bgcolor = Wx::Colour->new( $c->config->Read('image_bgcolor') );
#     $self->{ctrl_colorpicker} = Wx::ColourPickerCtrl->new($self->{notebook_settings_panel_bg}, -1, $bgcolor, wxDefaultPosition, wxDefaultSize, );

# ADD SUPER::__do_layout
#     $self->{sizer_bg_line1}->Add($self->{ctrl_colorpicker}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
    
    EVT_COLOURPICKER_CHANGED( $self, $self->{ctrl_colorpicker}, \&on_change );
    
    $self->{text_ctrl_default_image}->SetEditable(0);
    EVT_BUTTON($self, $self->{button_default_image}, \&file_dialog);
    
    $self;
}

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

sub default_image_custom {
    my $self = shift;
    
    if (@_) {
        my $custom = shift; # true(custom) or false(default)
        if ($custom) {
            $self->{radio_btn_default_image_path}->SetValue(1);
        }
        else {
            $self->{radio_btn_default_image_default}->SetValue(1);
        }
    }
    $self->{radio_btn_default_image_path}->GetValue;
}

sub default_image_path {
    my $self = shift;
    $self->{text_ctrl_default_image}->SetValue(@_) if @_;
    $self->{text_ctrl_default_image}->GetValue;
}

sub image_bgcolor {
    my $self = shift;
    if (@_) {
        my $c = NNPV::Controller->instance;
        my $bgcolor = Wx::Colour->new( $c->config->Read('image_bgcolor') );
        $self->{image_bgcolor} = shift;
        $self->{image_bgcolor_changed} = 1 if $bgcolor ne $self->{image_bgcolor};
    }
    $self->{image_bgcolor};
}

sub image_cache_onoff {
    my $self = shift;
    $self->{checkbox_cache}->SetValue(@_) if @_;
    $self->{checkbox_cache}->GetValue;
}

sub image_load_nowait_onoff {
    my $self = shift;
    $self->{checkbox_load_nowait}->SetValue(@_) if @_;
    $self->{checkbox_load_nowait}->GetValue;
}

sub image_mouse_click_onoff {
    my $self = shift;
    $self->{checkbox_mouse_click}->SetValue(@_) if @_;
    $self->{checkbox_mouse_click}->GetValue;
}

sub image_mouse_wheel_onoff {
    my $self = shift;
    $self->{checkbox_mouse_wheel}->SetValue(@_) if @_;
    $self->{checkbox_mouse_wheel}->GetValue;
}

sub file_dialog {
    my $self = shift;
    
    my $dialog = Wx::FileDialog->new(
        $self,
        "ファイルを開く",
        $self->{previous_directory} || '',
        $self->{previous_file} || '',
        (join '|', 'JPEGファイル (*.jpg)|*.jpg', 'PNGファイル (*.png)|*.png', 'GIFファイル (*.gif)|*.gif', 'BMPファイル (*.bmp)|*.bmp'),
        wxFD_OPEN,
    );
    
    unless ($dialog->ShowModal == wxID_CANCEL) {
        my ($path) = $dialog->GetPaths;
        if ($path) {
            $self->default_image_custom(1);
            $self->default_image_path($path);
        }
    }
    
    $dialog->Destroy;
}

sub on_change {
    my( $self, $event ) = @_;
    $self->image_bgcolor( $event->GetColour->GetAsString(wxC2S_HTML_SYNTAX) );
}
1;
