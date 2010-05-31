package NNPV::Frame::Main;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Frame::Constants;
use NNPV;
use NNPV::Controller;
use NNPV::ImageLoader;
use NNPV::DND;
use NNPV::FileSystem::Functions;
use NNPV::Image::Cache;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(NNPV::Frame::_Main);

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
) );

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    
    $self->{bitmap_main}->SetBitmap( Wx::Bitmap->new($NNPV::IMAGE_WIDTH, $NNPV::IMAGE_HEIGHT) );
    $self->{bitmap_main}->Refresh();
    $self->{sizer_main}->Fit($self);
    $self->{sizer_top}->Fit($self);
    
    $self->status_bar( $self->{statusbar_frame} );
    $self->static_bitmap( $self->{bitmap_main} );
    $self->menuitem_slideshow( $self->{menuitem_image_slideshow} );
    $self->menuitem_shuffle( $self->{menuitem_image_shuffle} );
    
    $self->init_event;
    
    $self->SetTitle("$NNPV::APPNAME version $NNPV::VERSION" . ($NNPV::ImageLoader::IMAGICK ? " [高画質]" : " [標準]"));
    
    $self->SetIcon(get_default_icon());
    
    $self->SetDropTarget(NNPV::DND::Image->new);
    
    $self;
}

sub init_event {
    my $self = shift;
    
    my $c = NNPV::Controller->instance;
    
    if ($^O eq 'MSWin32') {
        EVT_CHAR($self, \&on_keydown);
        EVT_LEFT_DOWN($self->{bitmap_main}, \&on_left_click);
        EVT_RIGHT_DOWN($self->{bitmap_main}, \&on_right_click);
        EVT_MOUSEWHEEL($self, \&on_wheel);
    }
    else {
        EVT_CHAR_HOOK($self, \&on_keydown);
        EVT_LEFT_DOWN($self->{bitmap_main}, \&on_left_click);
        EVT_RIGHT_DOWN($self->{bitmap_main}, \&on_right_click);
        EVT_MOUSEWHEEL($self->{panel_main}, \&on_wheel);
        $self->{panel_main}->SetFocusIgnoringChildren;
    }
    
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
        for my $argv (@ARGV) {
            $argv = Encode::decode_utf8($argv);
            if (not File::Spec->file_name_is_absolute($argv)) {
                $argv = Cwd::realpath($argv);
            }
            push @_argv_work, $argv;
        }
        $_args_parsed = 1;
        @ARGV = ();
    }
    
    # 退避された引数を１つずつ画像ロードリクエストキューに送る
    elsif (@_argv_work) {
        my $c = NNPV::Controller->instance;
        $c->load_image([shift @_argv_work]);
    }
    
    # 画像カウントリクエストキューがあれば処理する
    elsif (@NNPV::ImageLoader::_count) {
        $self->stop_slideshow_timer if $self->{timer_slideshow} and $self->{timer_slideshow}->IsRunning;
        
        my $c = NNPV::Controller->instance;
        do {
            ++$NNPV::ImageLoader::_count_index;
            my $file = shift @NNPV::ImageLoader::_count;
            
            if (is_dir($file->{path})) {
                my $config_dir = get_config_dir;
                return if $file->{path} =~ /^\Q$config_dir\E/;
                return unless open_dir(my $dh, $file->{path});
                my @children = ();
                for my $f (read_dir($dh)) {
                    next if $f =~ /^\.{1,2}$/;
                    my $struct = {%$file};
                    $struct->{path} = File::Spec->catfile($file->{path}, $f);
                    push @children, $struct;
                }
                close_dir($dh);
                unshift @NNPV::ImageLoader::_count, sort { $a->{path} cmp $b->{path} } @children;
            }
            elsif (can_read($file->{path})) {
                if (is_image($file->{path})) {
                    my $location = $file->{path};
                    if (defined $file->{url}) {
                        $location = $file->{url};
                    }
                    $NNPV::ImageLoader::_count++;
                    $NNPV::ImageLoader::_queue_all++;
                    my $num = sprintf("%5d", $NNPV::ImageLoader::_count);
                    $c->frame->status_bar->SetStatusText("画像ファイルを数えています... [$NNPV::ImageLoader::_count] $location");
                    push @NNPV::ImageLoader::_queue, $file;
                }
            }
        }
        while ( $c->config->Read('image_load_nowait_onoff')
            and $NNPV::ImageLoader::_count_index % $NNPV::ImageLoader::_idle_interval != 0
            and @NNPV::ImageLoader::_count
        );
    }
    
    # 画像ロードリクエストキューがあれば処理する
    elsif (@NNPV::ImageLoader::_queue) {
        my $c = NNPV::Controller->instance;
        do {
            ++$NNPV::ImageLoader::_queue_index;
            my $file = shift @NNPV::ImageLoader::_queue;
            my $per = sprintf("%3d", $NNPV::ImageLoader::_queue_index / $NNPV::ImageLoader::_queue_all * 100);
            my $location = $file->{path};
            if (defined $file->{url}) {
                $location = $file->{url};
            }
            $self->status_bar->SetStatusText("[${per}%] 読み込み中です... $location");
            my $bitmap;
            unless ($c->config->Read('image_cache_onoff') and $bitmap = cache_load($location)) {
                if ($bitmap = get_bitmap_from_file($file->{path})) {
                    cache_store($bitmap, $location) if $c->config->Read('image_cache_onoff');
                }
            }
            if ($bitmap and $bitmap->IsOk) {
                $file->{obj} = $bitmap;
                $c->store->add($file);
                if ($NNPV::ImageLoader::_queue_index == 1) {
                    $NNPV::ImageLoader::_first_loaded_image_index = $c->store->max;
                }
            }
            else {
                $self->status_bar->SetStatusText("失敗1 [" . $file->{path} . "]");
            }
            
            # キューが空っぽになったら、追加されたファイルのうちの最初のファイルを描画
            unless (@NNPV::ImageLoader::_queue) {
                $self->draw_image($c->store->get($NNPV::ImageLoader::_first_loaded_image_index || 0));
                $NNPV::ImageLoader::_first_loaded_image_index = undef;
                
                $c->update_status_bar($NNPV::ImageLoader::_queue_all . "件追加されました");
                $NNPV::ImageLoader::_queue_all = 0;
                $NNPV::ImageLoader::_queue_index = 0;
                $NNPV::ImageLoader::_count = 0;
                
                $self->Raise();
                $self->start_slideshow_timer if $self->slideshow;
            }
        }
        while ( $c->config->Read('image_load_nowait_onoff')
            and $NNPV::ImageLoader::_queue_index % $NNPV::ImageLoader::_idle_interval != 0
            and @NNPV::ImageLoader::_queue
        );
    }
}

sub image_load_cancel {
    my $self = shift;
    
    my $c = NNPV::Controller->instance;
    
    # 追加されたファイルのうちの最初のファイルを描画
    $self->draw_image($c->store->get($NNPV::ImageLoader::_first_loaded_image_index || 0)) if $c->store->count > 0;
    $NNPV::ImageLoader::_first_loaded_image_index = undef;
    
    $c->update_status_bar("読み込みが中断されました") if @NNPV::ImageLoader::_queue;
    @NNPV::ImageLoader::_queue = ();
    @NNPV::ImageLoader::_count = ();
    $NNPV::ImageLoader::_queue_all = 0;
    $NNPV::ImageLoader::_queue_index = 0;
    $NNPV::ImageLoader::_count = 0;
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

sub on_left_click {
    my($self, $event) = @_;
    my $c = NNPV::Controller->instance;
    $c->image_next;
}

sub on_right_click {
    my($self, $event) = @_;
    my $c = NNPV::Controller->instance;
    $c->image_prev;
}

sub on_wheel {
    my($self, $event) = @_;
    my $c = NNPV::Controller->instance;
    my $delta = $event->GetWheelDelta();
    $delta or ($delta = 120); # XXX why is this zero?
    my $dist = $event->GetWheelRotation() / $delta;
#    print "delta is $delta, $dist\n";
    if ($dist > 0) {
        $c->image_next;
    }
    elsif ($dist < 0) {
        $c->image_prev;
    }
}

sub on_keydown {
    my($self, $event) = @_;
    my $uni = Wx::wxUNICODE();
    my $key = $event->GetKeyCode;
    my $ukey = $event->GetUnicodeKey;
    
#    printf "KeyCode[%3d], UnicodeKey[%3d], wxUNICODE[%d]\n", $key, $ukey, $uni;
    
    my $c = NNPV::Controller->instance;
    my $f = $c->frame;
    
    if    ($key ==  13) { $c->image_next;        } # Enter
    elsif ($key ==  27) { $f->image_load_cancel; } # ESC
    elsif ($key ==  32) { $c->image_next;        } # Space
    elsif ($key ==  43) { $c->image_next;        } # ＋(テンキー)
    elsif ($key ==  45) { $c->image_prev;        } # －(テンキー)
    elsif ($key ==  48) { $c->image_get(9);      } # 0(テンキー)
    elsif ($key ==  49) { $c->image_get(0);      } # 1(テンキー)
    elsif ($key ==  50) { $c->image_get(1);      } # 2(テンキー)
    elsif ($key ==  51) { $c->image_get(2);      } # 3(テンキー)
    elsif ($key ==  52) { $c->image_get(3);      } # 4(テンキー)
    elsif ($key ==  53) { $c->image_get(4);      } # 5(テンキー)
    elsif ($key ==  54) { $c->image_get(5);      } # 6(テンキー)
    elsif ($key ==  55) { $c->image_get(6);      } # 7(テンキー)
    elsif ($key ==  56) { $c->image_get(7);      } # 8(テンキー)
    elsif ($key ==  57) { $c->image_get(8);      } # 9(テンキー)
    elsif ($key == 314) { $c->image_prev;        } # ←
    elsif ($key == 315) { $c->image_next;        } # ↑
    elsif ($key == 316) { $c->image_next;        } # →
    elsif ($key == 317) { $c->image_prev;        } # ↓
    elsif ($key == 366) { $c->image_next;        } # PageUp
    elsif ($key == 367) { $c->image_prev;        } # PageDown
    else                { $event->Skip();        }
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
