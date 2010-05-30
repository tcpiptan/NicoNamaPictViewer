package NNPV::Dialog::_Settings;

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

# begin wxGlade: NNPV::Dialog::_Settings::new

	$style = wxDEFAULT_DIALOG_STYLE|wxSTAY_ON_TOP 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{notebook_settings} = Wx::Notebook->new($self, -1, wxDefaultPosition, wxDefaultSize, 0);
	$self->{notebook_settings_panel_cache} = Wx::Panel->new($self->{notebook_settings}, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{notebook_settings_panel_bg} = Wx::Panel->new($self->{notebook_settings}, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{notebook_settings_panel_image} = Wx::Panel->new($self->{notebook_settings}, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{notebook_settings_panel_slideshow} = Wx::Panel->new($self->{notebook_settings}, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{spin_ctrl_slideshow} = Wx::SpinCtrl->new($self->{notebook_settings_panel_slideshow}, -1, "10", wxDefaultPosition, wxDefaultSize, wxSP_ARROW_KEYS, 1, 3600, 10);
	$self->{label_slideshow} = Wx::StaticText->new($self->{notebook_settings_panel_slideshow}, -1, "秒毎に切り替え", wxDefaultPosition, wxDefaultSize, );
	$self->{radio_btn_default_image_default} = Wx::RadioButton->new($self->{notebook_settings_panel_image}, -1, "デフォルト画像", wxDefaultPosition, wxDefaultSize, wxRB_GROUP);
	$self->{radio_btn_default_image_path} = Wx::RadioButton->new($self->{notebook_settings_panel_image}, -1, "ファイル指定", wxDefaultPosition, wxDefaultSize, );
	$self->{text_ctrl_default_image} = Wx::TextCtrl->new($self->{notebook_settings_panel_image}, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{button_default_image} = Wx::Button->new($self->{notebook_settings_panel_image}, -1, "選択...");
	$self->{label_bg_color} = Wx::StaticText->new($self->{notebook_settings_panel_bg}, -1, "背景色:", wxDefaultPosition, wxDefaultSize, );
	$self->{checkbox_cache} = Wx::CheckBox->new($self->{notebook_settings_panel_cache}, -1, "キャッシュを有効にする", wxDefaultPosition, wxDefaultSize, );
	$self->{wxID_OK} = Wx::Button->new($self, wxID_OK, "");
	$self->{wxID_CANCEL} = Wx::Button->new($self, wxID_CANCEL, "");

    my $c = NNPV::Controller->instance;
    my $bgcolor = Wx::Colour->new( $c->config->Read('image_bgcolor') );
    $self->{ctrl_colorpicker} = Wx::ColourPickerCtrl->new($self->{notebook_settings_panel_bg}, -1, $bgcolor, wxDefaultPosition, wxDefaultSize, );

	$self->__set_properties();
	$self->__do_layout();

# end wxGlade
	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: NNPV::Dialog::_Settings::__set_properties

	$self->SetTitle("設定");
	$self->{spin_ctrl_slideshow}->SetMinSize(Wx::Size->new(64, -1));
	$self->{radio_btn_default_image_default}->SetValue(1);
	$self->{text_ctrl_default_image}->SetMinSize(Wx::Size->new(160, -1));
	$self->{checkbox_cache}->SetValue(1);
	$self->{wxID_OK}->SetFocus();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: NNPV::Dialog::_Settings::__do_layout

	$self->{sizer_top} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_button} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_cache} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_cache_line1} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_bg} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_bg_line1} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_default_image} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_default_image_line2} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_default_mage_line1} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_slideshow} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_slideshow_line1} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_slideshow_line1}->Add($self->{spin_ctrl_slideshow}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_slideshow_line1}->Add($self->{label_slideshow}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_slideshow}->Add($self->{sizer_slideshow_line1}, 1, 0, 0);
	$self->{notebook_settings_panel_slideshow}->SetSizer($self->{sizer_slideshow});
	$self->{sizer_default_mage_line1}->Add($self->{radio_btn_default_image_default}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_default_image}->Add($self->{sizer_default_mage_line1}, 1, wxEXPAND, 0);
	$self->{sizer_default_image_line2}->Add($self->{radio_btn_default_image_path}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_default_image_line2}->Add($self->{text_ctrl_default_image}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_default_image_line2}->Add($self->{button_default_image}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_default_image}->Add($self->{sizer_default_image_line2}, 1, wxEXPAND, 0);
	$self->{notebook_settings_panel_image}->SetSizer($self->{sizer_default_image});
	$self->{sizer_bg_line1}->Add($self->{label_bg_color}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
    $self->{sizer_bg_line1}->Add($self->{ctrl_colorpicker}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_bg}->Add($self->{sizer_bg_line1}, 1, wxEXPAND, 0);
	$self->{notebook_settings_panel_bg}->SetSizer($self->{sizer_bg});
	$self->{sizer_cache_line1}->Add($self->{checkbox_cache}, 0, wxALL|wxALIGN_CENTER_VERTICAL, 4);
	$self->{sizer_cache}->Add($self->{sizer_cache_line1}, 1, wxEXPAND, 0);
	$self->{notebook_settings_panel_cache}->SetSizer($self->{sizer_cache});
	$self->{notebook_settings}->AddPage($self->{notebook_settings_panel_slideshow}, "スライドショー");
	$self->{notebook_settings}->AddPage($self->{notebook_settings_panel_image}, "初期画面");
	$self->{notebook_settings}->AddPage($self->{notebook_settings_panel_bg}, "背景");
	$self->{notebook_settings}->AddPage($self->{notebook_settings_panel_cache}, "キャッシュ");
	$self->{sizer_top}->Add($self->{notebook_settings}, 1, wxALL, 4);
	$self->{sizer_button}->Add($self->{wxID_OK}, 0, 0, 0);
	$self->{sizer_button}->Add($self->{wxID_CANCEL}, 0, wxLEFT, 10);
	$self->{sizer_top}->Add($self->{sizer_button}, 0, wxALL|wxALIGN_RIGHT, 4);
	$self->SetSizer($self->{sizer_top});
	$self->{sizer_top}->Fit($self);
	$self->Layout();

# end wxGlade
}

# end of class NNPV::Dialog::_Settings

1;
