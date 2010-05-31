package NNPV::Frame::_Main;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Frame::Constants;
use NNPV;
use Wx qw[:everything];
use base qw(Wx::Frame);

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: NNPV::Frame::_tmp_Main::new

	$style = wxCAPTION|wxCLOSE_BOX|wxMINIMIZE_BOX|wxSTAY_ON_TOP|wxSYSTEM_MENU|wxCLIP_CHILDREN 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{panel_main} = Wx::ScrolledWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);
	

	# Menu Bar

	$self->{menubar_frame} = Wx::MenuBar->new();
	my $wxglade_tmp_menu;
	$self->{menu_file} = Wx::Menu->new();
	$self->{menuitem_file_open} = $self->{menu_file}->Append(MENU_FILE_OPEN, "開く(&O)...\tCtrl+O", "開く...");
	$self->{menu_file}->AppendSeparator();
	$self->{menuitem_file_exit} = $self->{menu_file}->Append(wxID_EXIT, "終了(&X)", "終了");
	$self->{menubar_frame}->Append($self->{menu_file}, "ファイル(&F)");
	$self->{menu_image} = Wx::Menu->new();
	$self->{menuitem_image_copy} = $self->{menu_image}->Append(MENU_IMAGE_COPY, "コピー\tCtrl+C", "コピー");
	$self->{menu_image}->AppendSeparator();
	$self->{menuitem_image_slideshow} = $self->{menu_image}->Append(MENU_IMAGE_SLIDESHOW, "スライドショー\tS", "スライドショー", 1);
	$self->{menuitem_image_shuffle} = $self->{menu_image}->Append(MENU_IMAGE_SHUFFLE, "シャッフル\tR", "シャッフル", 1);
	$self->{menu_image}->AppendSeparator();
	$self->{menuitem_image_url} = $self->{menu_image}->Append(MENU_IMAGE_URL, "Webから取得...\tU", "Webから取得...");
	$self->{menu_image}->AppendSeparator();
	$self->{menuitem_image_prev} = $self->{menu_image}->Append(MENU_IMAGE_PREV, "前の画像\tP", "前の画像");
	$self->{menuitem_image_next} = $self->{menu_image}->Append(MENU_IMAGE_NEXT, "次の画像\tN", "次の画像");
	$self->{menu_image}->AppendSeparator();
	$self->{menuitem_image_first} = $self->{menu_image}->Append(MENU_IMAGE_FIRST, "最初の画像\tCtrl+H", "最初の画像");
	$self->{menuitem_image_last} = $self->{menu_image}->Append(MENU_IMAGE_LAST, "最後の画像\tCtrl+E", "最後の画像");
	$self->{menu_image}->AppendSeparator();
	$self->{menuitem_image_0} = $self->{menu_image}->Append(MENU_IMAGE_1, "1番目の画像\t1", "1番目の画像");
	$self->{menuitem_image_1} = $self->{menu_image}->Append(MENU_IMAGE_2, "2番目の画像\t2", "2番目の画像");
	$self->{menuitem_image_2} = $self->{menu_image}->Append(MENU_IMAGE_3, "3番目の画像\t3", "3番目の画像");
	$self->{menuitem_image_3} = $self->{menu_image}->Append(MENU_IMAGE_4, "4番目の画像\t4", "4番目の画像");
	$self->{menuitem_image_4} = $self->{menu_image}->Append(MENU_IMAGE_5, "5番目の画像\t5", "5番目の画像");
	$self->{menuitem_image_5} = $self->{menu_image}->Append(MENU_IMAGE_6, "6番目の画像\t6", "6番目の画像");
	$self->{menuitem_image_6} = $self->{menu_image}->Append(MENU_IMAGE_7, "7番目の画像\t7", "7番目の画像");
	$self->{menuitem_image_7} = $self->{menu_image}->Append(MENU_IMAGE_8, "8番目の画像\t8", "8番目の画像");
	$self->{menuitem_image_8} = $self->{menu_image}->Append(MENU_IMAGE_9, "9番目の画像\t9", "9番目の画像");
	$self->{menuitem_image_9} = $self->{menu_image}->Append(MENU_IMAGE_0, "10番目の画像\t0", "10番目の画像");
	$self->{menu_image}->AppendSeparator();
	$self->{menuitem_image_delete} = $self->{menu_image}->Append(MENU_IMAGE_DELETE, "この画像を削除\tDelete", "この画像を削除");
	$self->{menuitem_image_deleteall} = $self->{menu_image}->Append(MENU_IMAGE_DELETEALL, "全ての画像を削除\tCtrl+Delete", "全ての画像を削除");
	$self->{menubar_frame}->Append($self->{menu_image}, "画像(&I)");
	$self->{menu_other} = Wx::Menu->new();
	$self->{menuitem_other_settings} = $self->{menu_other}->Append(MENU_OTHER_SETTINGS, "設定...", "設定...");
	$self->{menu_other}->AppendSeparator();
	$self->{menuitem_other_about} = $self->{menu_other}->Append(wxID_ABOUT, "バージョン情報(&A)", "バージョン情報");
	$self->{menubar_frame}->Append($self->{menu_other}, "その他(&O)");
	$self->SetMenuBar($self->{menubar_frame});
	
# Menu Bar end

	$self->{statusbar_frame} = $self->CreateStatusBar(3, 0);
	$self->{bitmap_main} = Wx::StaticBitmap->new($self->{panel_main}, -1, wxNullBitmap, wxDefaultPosition, wxDefaultSize, );

	$self->__set_properties();
	$self->__do_layout();

# end wxGlade
	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: NNPV::Frame::_tmp_Main::__set_properties

	$self->{statusbar_frame}->SetStatusWidths(-1,64,64);
	
	my( @statusbar_frame_fields ) = (
		"",
		"",
		""
	);

	if( @statusbar_frame_fields ) {
		$self->{statusbar_frame}->SetStatusText($statusbar_frame_fields[$_], $_) 	
		for 0 .. $#statusbar_frame_fields ;
	}
	$self->{panel_main}->SetScrollRate(0, 0);

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: NNPV::Frame::_tmp_Main::__do_layout

	$self->{sizer_top} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_main} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_main}->Add($self->{bitmap_main}, 0, 0, 0);
	$self->{panel_main}->SetSizer($self->{sizer_main});
	$self->{sizer_top}->Add($self->{panel_main}, 1, wxEXPAND, 0);
	$self->SetSizer($self->{sizer_top});
	$self->{sizer_top}->Fit($self);
	$self->Layout();

# end wxGlade
}

# end of class NNPV::Frame::_tmp_Main

1;
