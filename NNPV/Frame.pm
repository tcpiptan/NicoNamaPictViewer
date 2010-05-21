package NNPV::Frame;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use NNPV::Controller;
use NNPV::ImageLoader;
use NNPV::DND;

use Wx qw(
    wxDefaultPosition
    wxDefaultSize
    wxDEFAULT_FRAME_STYLE
    wxSTAY_ON_TOP
    wxMINIMIZE_BOX
    wxMAXIMIZE_BOX
    wxRESIZE_BORDER
    wxBITMAP_TYPE_XPM
    wxFD_OPEN
    wxID_CANCEL
    wxID_EXIT
    wxID_ABOUT
    wxEVT_IDLE
    wxFD_MULTIPLE
    wxTIMER_CONTINUOUS
    wxTIMER_ONE_SHOT
    wxEVT_TIMER
);
use Wx::Event qw(EVT_KEY_DOWN EVT_MENU EVT_MENU_CLOSE EVT_TIMER);

use base qw(Wx::Frame Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(status_bar static_bitmap timer) );

use constant {
    MENU_FILE_OPEN       => 101,
    
    MENU_IMAGE_PREV      => 201,
    MENU_IMAGE_NEXT      => 202,
    MENU_IMAGE_FIRST     => 203,
    MENU_IMAGE_LAST      => 204,
    MENU_IMAGE_DELETE    => 205,
    MENU_IMAGE_DELETEALL => 206,
    
    MENU_IMAGE_0         => 210,
    MENU_IMAGE_1         => 211,
    MENU_IMAGE_2         => 212,
    MENU_IMAGE_3         => 213,
    MENU_IMAGE_4         => 214,
    MENU_IMAGE_5         => 215,
    MENU_IMAGE_6         => 216,
    MENU_IMAGE_7         => 217,
    MENU_IMAGE_8         => 218,
    MENU_IMAGE_9         => 219,
};


sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(
        undef,
        -1,
        "$NNPV::APPNAME version $NNPV::VERSION" . ($NNPV::ImageLoader::USE_WX_PERL_IMAGICK ? " [高画質]" : " [標準]"),
        wxDefaultPosition,
        wxDefaultSize,
        (wxDEFAULT_FRAME_STYLE | wxSTAY_ON_TOP) ^ (wxMAXIMIZE_BOX | wxRESIZE_BORDER)
#        (wxDEFAULT_FRAME_STYLE | wxSTAY_ON_TOP) ^ (wxMINIMIZE_BOX | wxMAXIMIZE_BOX | wxRESIZE_BORDER)
    );
    
    my $menu_file  = Wx::Menu->new();
    my $menu_image = Wx::Menu->new();
    my $menu_help  = Wx::Menu->new();
    
    $menu_file->Append(MENU_FILE_OPEN, "開く(&O)...\tCtrl+O", "開く");
    $menu_file->AppendSeparator();
    $menu_file->Append(wxID_EXIT, "終了(&X)", "終了");
    
    $menu_image->Append(MENU_IMAGE_PREV,      "前の画像\tP", "前の画像");
    $menu_image->Append(MENU_IMAGE_NEXT,      "次の画像\tN", "次の画像");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_FIRST,     "最初の画像\tCtrl+H", "最初の画像");
    $menu_image->Append(MENU_IMAGE_LAST,      "最後の画像\tCtrl+E", "最後の画像");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_1,         "1番目の画像\t1", "1番目の画像");
    $menu_image->Append(MENU_IMAGE_2,         "2番目の画像\t2", "2番目の画像");
    $menu_image->Append(MENU_IMAGE_3,         "3番目の画像\t3", "3番目の画像");
    $menu_image->Append(MENU_IMAGE_4,         "4番目の画像\t4", "4番目の画像");
    $menu_image->Append(MENU_IMAGE_5,         "5番目の画像\t5", "5番目の画像");
    $menu_image->Append(MENU_IMAGE_6,         "6番目の画像\t6", "6番目の画像");
    $menu_image->Append(MENU_IMAGE_7,         "7番目の画像\t7", "7番目の画像");
    $menu_image->Append(MENU_IMAGE_8,         "8番目の画像\t8", "8番目の画像");
    $menu_image->Append(MENU_IMAGE_9,         "9番目の画像\t9", "9番目の画像");
    $menu_image->Append(MENU_IMAGE_0,         "10番目の画像\t0", "10番目の画像");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_DELETE,    "この画像を削除\tDelete", "この画像を削除");
    $menu_image->Append(MENU_IMAGE_DELETEALL, "全ての画像を削除(&T)\tCtrl+Delete", "全ての画像を削除");
    
    $menu_help->Append(wxID_ABOUT, "バージョン情報(&A)", "バージョン情報");
    
    my $menubar = Wx::MenuBar->new();
    $menubar->Append($menu_file,  "ファイル(&F)");
    $menubar->Append($menu_image, "画像(&I)");
    $menubar->Append($menu_help,  "ヘルプ(&H)");
    $self->SetMenuBar($menubar);
    
    my $controller = NNPV::Controller->instance;
    
    EVT_MENU($self, MENU_FILE_OPEN, \&file_dialog);
    EVT_MENU($self, wxID_EXIT, sub {$_[0]->Close});
    
    EVT_MENU($self, MENU_IMAGE_PREV,      sub { $controller->image_prev });
    EVT_MENU($self, MENU_IMAGE_NEXT,      sub { $controller->image_next });
    EVT_MENU($self, MENU_IMAGE_FIRST,     sub { $controller->image_first });
    EVT_MENU($self, MENU_IMAGE_LAST,      sub { $controller->image_last });
    EVT_MENU($self, MENU_IMAGE_1,         sub { $controller->image_get(0) });
    EVT_MENU($self, MENU_IMAGE_2,         sub { $controller->image_get(1) });
    EVT_MENU($self, MENU_IMAGE_3,         sub { $controller->image_get(2) });
    EVT_MENU($self, MENU_IMAGE_4,         sub { $controller->image_get(3) });
    EVT_MENU($self, MENU_IMAGE_5,         sub { $controller->image_get(4) });
    EVT_MENU($self, MENU_IMAGE_6,         sub { $controller->image_get(5) });
    EVT_MENU($self, MENU_IMAGE_7,         sub { $controller->image_get(6) });
    EVT_MENU($self, MENU_IMAGE_8,         sub { $controller->image_get(7) });
    EVT_MENU($self, MENU_IMAGE_9,         sub { $controller->image_get(8) });
    EVT_MENU($self, MENU_IMAGE_0,         sub { $controller->image_get(9) });
    EVT_MENU($self, MENU_IMAGE_DELETE,    sub { $controller->image_delete });
    EVT_MENU($self, MENU_IMAGE_DELETEALL, sub { $controller->image_delete_all });
    
    EVT_MENU($self, wxID_ABOUT, \&on_about );
    EVT_MENU_CLOSE($self, sub { $controller->update_status_bar });
    
    $self->SetIcon(get_default_icon());
    
    # default black bitmap
    my $bitmap = get_default_bitmap();
    $self->static_bitmap(Wx::StaticBitmap->new($self, -1, $bitmap, wxDefaultPosition));
    
    $self->status_bar( $self->CreateStatusBar );
    
    $self->SetDropTarget(NNPV::DND->new);
    
    EVT_KEY_DOWN($self, \&OnKeyDown);
    
    return $self;
}

sub draw_image {
    my $self = shift;
    my $image = shift;
    
    $self->static_bitmap->SetBitmap($image->{obj});
    $self->static_bitmap->Refresh;
}

sub file_dialog {
    my $self = shift;
    
    my $dialog = Wx::FileDialog->new(
        $self,
        "ファイルを開く",
        $self->{previous_directory} || '',
        $self->{previous_file} || '',
        (join '|', 'JPEGファイル (*.jpg)|*.jpg', 'PNGファイル (*.png)|*.png', 'GIFファイル (*.gif)|*.gif', 'BMPファイル (*.bmp)|*.bmp'),
        wxFD_OPEN|wxFD_MULTIPLE
    );
    
    unless ($dialog->ShowModal == wxID_CANCEL) {
        my @paths = $dialog->GetPaths;
        
        if (@paths > 0) {
            $self->{previous_file} = $paths[@paths-1];
        }
        
        $self->{previous_directory} = $dialog->GetDirectory;
        
        NNPV::Controller->instance->load_image(\@paths);
    }
    
    $dialog->Destroy;
}

sub on_about {
    my $self = shift;
    
    my $info = Wx::AboutDialogInfo->new;
    
    $info->SetIcon(get_default_icon());
    $info->SetName($NNPV::APPNAME);
    $info->SetVersion($NNPV::VERSION);
    $info->SetDescription("\n"
      . "ニコ生用のちょっとした画像ビューアーです。\n"
      . "ニコ生用のため、閲覧サイズが 512 x 384 固定になっています。\n"
      . "放送時にスクリーンキャプチャのお供としてご使用ください。\n"
      . "\n"
      . "作者「TCP(ぴーたん)」は、あなたが本ソフトのエラー、バグ、\n"
      . "または瑕疵により被るいかなる問題も一切責任を持ちません。 \n"
      . "自己責任においてご使用ください。\n"
      . "\n"
    );
    $info->SetCopyright( '(C) 2010 TCP(ぴーたん) <ptan@ptan.info>' . "\n" . 'Twitter ID: @tcpiptan' );
    $info->SetWebSite( 'http://ptan.info/', '作者のウェブサイトはこちら' );
    
    Wx::AboutBox( $info );
}

sub OnKeyDown {
    my( $self, $event ) = @_;
#    print "KEYCODE: ", $event->GetKeyCode(), "\n";
    
    my $controller = NNPV::Controller->instance;
    
    # →キー
    if( $event->GetKeyCode() == 316 ) {
        $controller->image_next;
    }
    # ←キー
    elsif( $event->GetKeyCode() == 314 ) {
        $controller->image_prev;
    }
    # ↑キー
    elsif( $event->GetKeyCode() == 315 ) {
        $controller->image_next;
    }
    # ↓キー
    elsif( $event->GetKeyCode() == 317 ) {
        $controller->image_prev;
    }
    # PageUpキー
    elsif( $event->GetKeyCode() == 366 ) {
        $controller->image_next;
    }
    # PageDownキー
    elsif( $event->GetKeyCode() == 367 ) {
        $controller->image_prev;
    }
    # Enterキー
    elsif( $event->GetKeyCode() == 13 ) {
        $controller->image_next;
    }
    # Enterキー(テンキー)
    elsif( $event->GetKeyCode() == 370 ) {
        $controller->image_next;
    }
    # ＋キー(テンキー)
    elsif( $event->GetKeyCode() == 388 ) {
        $controller->image_next;
    }
    # －キー(テンキー)
    elsif( $event->GetKeyCode() == 390 ) {
        $controller->image_prev;
    }
    # Spaceキー
    elsif( $event->GetKeyCode() == 32 ) {
        $controller->image_next;
    }
    # 0キー(テンキー)
    elsif( $event->GetKeyCode() == 324 ) {
        $controller->image_get(9);
    }
    # 1キー(テンキー)
    elsif( $event->GetKeyCode() == 325 ) {
        $controller->image_get(0);
    }
    # 2キー(テンキー)
    elsif( $event->GetKeyCode() == 326 ) {
        $controller->image_get(1);
    }
    # 3キー(テンキー)
    elsif( $event->GetKeyCode() == 327 ) {
        $controller->image_get(2);
    }
    # 4キー(テンキー)
    elsif( $event->GetKeyCode() == 328 ) {
        $controller->image_get(3);
    }
    # 5キー(テンキー)
    elsif( $event->GetKeyCode() == 329 ) {
        $controller->image_get(4);
    }
    # 6キー(テンキー)
    elsif( $event->GetKeyCode() == 330 ) {
        $controller->image_get(5);
    }
    # 7キー(テンキー)
    elsif( $event->GetKeyCode() == 331 ) {
        $controller->image_get(6);
    }
    # 8キー(テンキー)
    elsif( $event->GetKeyCode() == 332 ) {
        $controller->image_get(7);
    }
    # 9キー(テンキー)
    elsif( $event->GetKeyCode() == 333 ) {
        $controller->image_get(8);
    }
    else {
        $event->Skip();
    }
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
