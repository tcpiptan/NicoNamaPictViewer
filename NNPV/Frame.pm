package NNPV::Frame;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use NNPV::Controller;
use NNPV::ImageLoader;
use NNPV::DND;
use NNPV::FileSystem::Functions;
use NNPV::Image::Cache;

use Wx qw(:everything);
use Wx::Event qw(:everything);

# 0.19改にてドラッグ＆ドロップに対応
BEGIN {
    eval { require Win32::Unicode::Native; };
    unless ($@) {
        Win32::Unicode::Native->import;
    }
};

use base qw(Wx::Frame Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(
    status_bar
    static_bitmap
    slideshow
    menuitem_slideshow
    shuffle
    menuitem_shuffle
    sizer
) );

use constant {
    MENU_FILE_OPEN       => 1001,
    
    MENU_IMAGE_PREV      => 2001,
    MENU_IMAGE_NEXT      => 2002,
    MENU_IMAGE_FIRST     => 2003,
    MENU_IMAGE_LAST      => 2004,
    MENU_IMAGE_DELETE    => 2005,
    MENU_IMAGE_DELETEALL => 2006,
    
    MENU_IMAGE_0         => 2101,
    MENU_IMAGE_1         => 2102,
    MENU_IMAGE_2         => 2103,
    MENU_IMAGE_3         => 2104,
    MENU_IMAGE_4         => 2105,
    MENU_IMAGE_5         => 2106,
    MENU_IMAGE_6         => 2107,
    MENU_IMAGE_7         => 2108,
    MENU_IMAGE_8         => 2109,
    MENU_IMAGE_9         => 2110,
    
    MENU_IMAGE_SLIDESHOW => 2201,
    MENU_IMAGE_SHUFFLE   => 2202,
    
    MENU_IMAGE_URL       => 2301,
    
    MENU_IMAGE_COPY      => 2401,
    
    MENU_OTHER_SETTINGS  => 3001,
    
    TIMER_IDLE           => 4001,
    TIMER_SLIDESHOW      => 4002,
    
    BUTTON_WGET          => 5001,
};


sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(
        undef,
        -1,
        "$NNPV::APPNAME version $NNPV::VERSION" . ($NNPV::ImageLoader::IMAGICK ? " [高画質]" : " [標準]"),
        wxDefaultPosition,
        wxDefaultSize,
        (wxDEFAULT_FRAME_STYLE | wxSTAY_ON_TOP) ^ (wxMAXIMIZE_BOX | wxRESIZE_BORDER)
    );
    
    $self->init_menu;
    $self->init_event;
    
    $self->SetIcon(get_default_icon());
    
    my $panel = Wx::Panel->new($self, -1, wxDefaultPosition, wxDefaultSize, );
    my $bitmap = Wx::Bitmap->new($NNPV::IMAGE_WIDTH, $NNPV::IMAGE_HEIGHT);
    $self->static_bitmap(Wx::StaticBitmap->new($panel, -1, $bitmap, wxDefaultPosition));
    
    $self->sizer( Wx::BoxSizer->new(wxVERTICAL) );
    $self->sizer->Add($panel, 0, 0, 0);
    $self->SetSizer($self->sizer);
    $self->sizer->Fit($self);
    
    my $status_bar = $self->CreateStatusBar(3);
    $status_bar->SetStatusWidths(-1,64,64);
    $self->status_bar($status_bar);
    
    $self->SetDropTarget(NNPV::DND::Image->new);
    
    $self;
}

sub init_menu {
    my $self = shift;
    
    my $menu_file  = Wx::Menu->new();
    $menu_file->Append(MENU_FILE_OPEN, "開く(&O)...\tCtrl+O", "開く");
    $menu_file->AppendSeparator();
    $menu_file->Append(wxID_EXIT, "終了(&X)", "終了");
    
    my $menu_image = Wx::Menu->new();
    $menu_image->Append(MENU_IMAGE_COPY, "コピー\tCtrl+C", "コピー");
    $menu_image->AppendSeparator();
    $self->menuitem_slideshow( $menu_image->AppendCheckItem(MENU_IMAGE_SLIDESHOW, "スライドショー\tS", "スライドショー") );
    $self->menuitem_shuffle(   $menu_image->AppendCheckItem(MENU_IMAGE_SHUFFLE,   "シャッフル\tR",     "シャッフル") );
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_URL, "Webから取得\tU", "Webから取得");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_PREV, "前の画像\tP", "前の画像");
    $menu_image->Append(MENU_IMAGE_NEXT, "次の画像\tN", "次の画像");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_FIRST, "最初の画像\tCtrl+H", "最初の画像");
    $menu_image->Append(MENU_IMAGE_LAST,  "最後の画像\tCtrl+E", "最後の画像");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_1, "1番目の画像\t1", "1番目の画像");
    $menu_image->Append(MENU_IMAGE_2, "2番目の画像\t2", "2番目の画像");
    $menu_image->Append(MENU_IMAGE_3, "3番目の画像\t3", "3番目の画像");
    $menu_image->Append(MENU_IMAGE_4, "4番目の画像\t4", "4番目の画像");
    $menu_image->Append(MENU_IMAGE_5, "5番目の画像\t5", "5番目の画像");
    $menu_image->Append(MENU_IMAGE_6, "6番目の画像\t6", "6番目の画像");
    $menu_image->Append(MENU_IMAGE_7, "7番目の画像\t7", "7番目の画像");
    $menu_image->Append(MENU_IMAGE_8, "8番目の画像\t8", "8番目の画像");
    $menu_image->Append(MENU_IMAGE_9, "9番目の画像\t9", "9番目の画像");
    $menu_image->Append(MENU_IMAGE_0, "10番目の画像\t0", "10番目の画像");
    $menu_image->AppendSeparator();
    $menu_image->Append(MENU_IMAGE_DELETE,    "この画像を削除\tDelete", "この画像を削除");
    $menu_image->Append(MENU_IMAGE_DELETEALL, "全ての画像を削除\tCtrl+Delete", "全ての画像を削除");
    
    my $menu_other = Wx::Menu->new();
    $menu_other->Append(MENU_OTHER_SETTINGS, "設定...", "設定...");
    $menu_other->AppendSeparator();
    $menu_other->Append(wxID_ABOUT, "バージョン情報(&A)", "バージョン情報");
    
    my $menubar = Wx::MenuBar->new();
    $menubar->Append($menu_file,  "ファイル(&F)");
    $menubar->Append($menu_image, "画像(&I)");
    $menubar->Append($menu_other, "その他(&O)");
    $self->SetMenuBar($menubar);
}

sub init_event {
    my $self = shift;
    
    my $c = NNPV::Controller->instance;
    
    EVT_MENU($self, MENU_FILE_OPEN,       \&file_dialog);
    EVT_MENU($self, wxID_EXIT,            sub { $_[0]->stop_slideshow_timer; $_[0]->Close} );
    
    EVT_MENU($self, MENU_IMAGE_PREV,      sub { $c->image_prev });
    EVT_MENU($self, MENU_IMAGE_NEXT,      sub { $c->image_next });
    EVT_MENU($self, MENU_IMAGE_FIRST,     sub { $c->image_first });
    EVT_MENU($self, MENU_IMAGE_LAST,      sub { $c->image_last });
    EVT_MENU($self, MENU_IMAGE_1,         sub { $c->image_get(0) });
    EVT_MENU($self, MENU_IMAGE_2,         sub { $c->image_get(1) });
    EVT_MENU($self, MENU_IMAGE_3,         sub { $c->image_get(2) });
    EVT_MENU($self, MENU_IMAGE_4,         sub { $c->image_get(3) });
    EVT_MENU($self, MENU_IMAGE_5,         sub { $c->image_get(4) });
    EVT_MENU($self, MENU_IMAGE_6,         sub { $c->image_get(5) });
    EVT_MENU($self, MENU_IMAGE_7,         sub { $c->image_get(6) });
    EVT_MENU($self, MENU_IMAGE_8,         sub { $c->image_get(7) });
    EVT_MENU($self, MENU_IMAGE_9,         sub { $c->image_get(8) });
    EVT_MENU($self, MENU_IMAGE_0,         sub { $c->image_get(9) });
    EVT_MENU($self, MENU_IMAGE_DELETE,    sub { $c->image_delete });
    EVT_MENU($self, MENU_IMAGE_DELETEALL, sub { $c->image_delete_all });
    
    EVT_MENU($self, MENU_IMAGE_SLIDESHOW, sub { $c->toggle_slideshow });
    EVT_MENU($self, MENU_IMAGE_SHUFFLE,   sub { $c->toggle_shuffle });
    
    EVT_MENU($self, MENU_IMAGE_URL,       sub { $c->show_dialog_url });
    
    EVT_MENU($self, MENU_IMAGE_COPY,      sub { $c->image_copy });
    
    EVT_MENU($self, MENU_OTHER_SETTINGS,  sub { $c->show_dialog_settings });
    EVT_MENU($self, wxID_ABOUT,           sub { $c->show_dialog_about });
    
    EVT_MENU_CLOSE($self,                 sub { $c->update_status_bar });
    
    EVT_TIMER($self, TIMER_SLIDESHOW,     \&on_slideshow_timer);
    
    EVT_KEY_DOWN($self,                   \&on_keydown);
    
    $self->{timer_idle} = Wx::Timer->new($self, TIMER_IDLE);
    EVT_TIMER( $self, TIMER_IDLE,         \&on_idle_timer );
    EVT_IDLE( $self,                      \&on_idle );
}

sub on_idle {
    my ( $self, $event ) = @_;
    
    if ($self->{timer_idle}->IsRunning) {
        $self->{timer_idle}->Stop;
    }
    $self->{timer_idle}->Start(100, wxTIMER_ONE_SHOT);
    $event->Skip(0);
}

my $_args_parsed;
my @_argv_work;
my $_argv_num;
sub on_idle_timer {
    my ( $self, $event, $force ) = @_;
    
    # アプリ起動時。引数を退避してクリアする
    # 必然的に、起動して最初のアイドルイベントがこれを行う(ただし@ARGVが設定されていれば)。
    if (!$_args_parsed and (@ARGV or $ENV{PAR_ARGC} > 0)) {
        $_argv_num  = scalar @ARGV;
        @_argv_work = @ARGV;
        $_args_parsed = 1;
        @ARGV = ();
    }
    
    # 退避された引数を１つずつ画像ロードリクエストキューに送る
    if (@_argv_work) {
        my $c = NNPV::Controller->instance;
        $c->load_image([shift @_argv_work]);
    }
    
    # 画像ロードリクエストキューがあれば処理する
    if (@NNPV::ImageLoader::_queue) {
        $self->stop_slideshow_timer if $self->{timer_slideshow} and $self->{timer_slideshow}->IsRunning;
        
        my $c = NNPV::Controller->instance;
        my $file = shift @NNPV::ImageLoader::_queue;
        my $per = sprintf("%3d", ($file->{num} + $NNPV::ImageLoader::_queue_sum - $file->{num_all}) / $NNPV::ImageLoader::_queue_sum * 100);
        my $location = $file->{target}->{path};
        if (defined $file->{target}->{url}) {
            $location = $file->{target}->{url};
        }
        $self->status_bar->SetStatusText("[${per}%] 読み込み中です... $location");
        my $bitmap;
        unless ($c->config->Read('image_cache_onoff') and $bitmap = cache_load($location)) {
            if ($bitmap = get_bitmap_from_file($file->{target}->{path})) {
                cache_store($bitmap, $location) if $c->config->Read('image_cache_onoff');
            }
        }
        if ($bitmap and $bitmap->IsOk) {
            $file->{target}->{obj} = $bitmap;
            $c->store->add($file->{target});
            if ($file->{num} == 1 and !defined($NNPV::ImageLoader::_first_loaded_image_index)) {
                $NNPV::ImageLoader::_first_loaded_image_index = $c->store->max;
            }
        }
        else {
            $self->status_bar->SetStatusText("失敗1 [" . $file->{target}->{path} . "]");
        }
        
        # キューが空っぽになったら、追加されたファイルのうちの最初のファイルを描画
        unless (@NNPV::ImageLoader::_queue) {
            $self->draw_image($c->store->get($NNPV::ImageLoader::_first_loaded_image_index || 0));
            $NNPV::ImageLoader::_first_loaded_image_index = undef;
            
            # キューが捌ける前に重ねて次のキュー追加要求が来たが、一旦捌けてしまったため、
            # 総数のクリアを保留する(次のキューが全て捌けた時に合わせて総数を表示するため)
            if ($NNPV::ImageLoader::_queueing_on_queueing) {
                $NNPV::ImageLoader::_queueing_on_queueing = 0;
            }
            
            # 追加されようとしているキューが無いなら、キューが全て捌けたので表示して総数をクリア
            else {
                $c->update_status_bar($NNPV::ImageLoader::_queue_sum . "件追加されました");
                $NNPV::ImageLoader::_queue_sum = 0;
            }
            
            $self->start_slideshow_timer if $self->slideshow;
        }
    }
}

sub image_load_cancel {
    my $self = shift;
    
    my $c = NNPV::Controller->instance;
    
    # 追加されたファイルのうちの最初のファイルを描画
    $self->draw_image($c->store->get($NNPV::ImageLoader::_first_loaded_image_index || 0));
    $NNPV::ImageLoader::_first_loaded_image_index = undef;
    
    $NNPV::ImageLoader::_queueing_on_queueing = 0;
    $NNPV::ImageLoader::_queue_sum = 0;
    @NNPV::ImageLoader::_queue = ();
    
    $c->update_status_bar("読み込みが中断されました");
}

sub draw_image {
    my $self = shift;
    my $image = shift;
    
    $self->static_bitmap->SetBitmap(centering_bitmap($image->{obj}));
    $self->static_bitmap->Refresh;
}

sub file_dialog {
    my $self = shift;
    
    my ($x, $y) = $self->GetPositionXY();
    my ($w, $h) = $self->GetSizeWH();
    
    # position is not implemented
    my $dialog = Wx::FileDialog->new(
        $self,
        "ファイルを開く",
        $self->{previous_directory} || '',
        $self->{previous_file} || '',
        (join '|', 'JPEGファイル (*.jpg)|*.jpg', 'PNGファイル (*.png)|*.png', 'GIFファイル (*.gif)|*.gif', 'BMPファイル (*.bmp)|*.bmp'),
        wxFD_OPEN|wxFD_MULTIPLE,
        [$x,$y+$h]
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

sub start_slideshow_timer {
    my $self = shift;
    
    my $c = NNPV::Controller->instance;
    
    $self->{timer_slideshow} = Wx::Timer->new($self, TIMER_SLIDESHOW);
    
    my $interval = $c->config->Read('slideshow_interval');
    $self->{timer_slideshow}->Start( $interval * 1000, wxTIMER_CONTINUOUS );
}

sub stop_slideshow_timer {
    my $self = shift;
    $self->{timer_slideshow}->Stop if ref($self->{timer_slideshow}) eq 'Wx::Timer';
}

sub on_slideshow_timer {
    my( $self, $event ) = @_;
    my $c = NNPV::Controller->instance;
    
    $c->image_next;
}

sub on_keydown {
    my( $self, $event ) = @_;
    my $uni = Wx::wxUNICODE();
    my $key = $event->GetKeyCode;
    my $ukey = $event->GetUnicodeKey;
    
    printf "KeyCode[%3d], UnicodeKey[%3d], wxUNICODE[%d]\n", $key, $ukey, $uni;
    
    my $c = NNPV::Controller->instance;
    
    if    ( $key == 316 ) { $c->image_next;           } # →
    elsif ( $key == 314 ) { $c->image_prev;           } # ←
    elsif ( $key == 315 ) { $c->image_next;           } # ↑
    elsif ( $key == 317 ) { $c->image_prev;           } # ↓
    elsif ( $key == 366 ) { $c->image_next;           } # PageUp
    elsif ( $key == 367 ) { $c->image_prev;           } # PageDown
    elsif ( $key ==  13 ) { $c->image_next;           } # Enter
    elsif ( $key ==  32 ) { $c->image_next;           } # Space
    elsif ( $key == 370 ) { $c->image_next;           } # Enter(テンキー)
    elsif ( $key == 388 ) { $c->image_next;           } # ＋(テンキー)
    elsif ( $key == 390 ) { $c->image_prev;           } # －(テンキー)
    elsif ( $key == 324 ) { $c->image_get(9);         } # 0(テンキー)
    elsif ( $key == 325 ) { $c->image_get(0);         } # 1(テンキー)
    elsif ( $key == 326 ) { $c->image_get(1);         } # 2(テンキー)
    elsif ( $key == 327 ) { $c->image_get(2);         } # 3(テンキー)
    elsif ( $key == 328 ) { $c->image_get(3);         } # 4(テンキー)
    elsif ( $key == 329 ) { $c->image_get(4);         } # 5(テンキー)
    elsif ( $key == 330 ) { $c->image_get(5);         } # 6(テンキー)
    elsif ( $key == 331 ) { $c->image_get(6);         } # 7(テンキー)
    elsif ( $key == 332 ) { $c->image_get(7);         } # 8(テンキー)
    elsif ( $key == 333 ) { $c->image_get(8);         } # 9(テンキー)
    elsif ( $key ==  27 ) { $self->image_load_cancel; } # ESC
    else                  { $event->Skip();           }
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
