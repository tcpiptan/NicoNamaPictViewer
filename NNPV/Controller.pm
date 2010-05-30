package NNPV::Controller;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::ImageStore;
use NNPV::ImageLoader;
use NNPV::Config;
use NNPV::Frame;
use NNPV::Dialog::Settings;
use NNPV::Dialog::Url;
use NNPV::FileSystem::Functions;

use Wx qw(:everything);
use File::Basename;

use base qw(Class::Singleton Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(app frame store config dialog_settings shuffle_table shuffle_index dialog_url) );

sub init {
    my $self = shift;
    
    Wx::InitAllImageHandlers();
    $self->shuffle_table([]);
    $self->shuffle_index(-1);
}

sub init_image {
    NNPV::ImageLoader::init();
}

sub init_store {
    my $self = shift;
    
    $self->store( NNPV::ImageStore->instance );
    $self->store->init;
}

sub init_app {
    my $self = shift;
    
    $self->app( Wx::SimpleApp->new );
    $self->app->SetAppName( $NNPV::APPNAME );
    $self->app->SetVendorName( $NNPV::VENDORNAME );
    $self->app;
}

sub init_config {
    my $self = shift;
    
    $self->config( NNPV::Config::init );
}

sub init_frame {
    my $self = shift;
    
    $self->frame( NNPV::Frame->new );
    $self->frame->slideshow( $self->config->Read('slideshow_onoff') );
    if ($self->frame->slideshow) {
        $self->frame->menuitem_slideshow->Check(1);
        $self->frame->status_bar->SetStatusText("スライドショー",1);
        $self->frame->start_slideshow_timer;
    }
    $self->frame->shuffle( $self->config->Read('shuffle_onoff') );
    if ($self->frame->shuffle) {
        $self->frame->menuitem_shuffle->Check(1);
        $self->frame->status_bar->SetStatusText("シャッフル",2);
    }
    $self->frame->draw_image( get_default_image() );
    $self->frame->Fit;
    $self->frame->Layout;
    
    $self->frame;
}

sub show_dialog_about {
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

sub show_dialog_settings {
    my $self = shift;
    
    my ($x, $y) = $self->frame->GetPositionXY();
    my ($w, $h) = $self->frame->GetSizeWH();
    
    $h += 24 if $^O ne 'MSWin32';
    $self->dialog_settings( NNPV::Dialog::Settings->new(undef, undef, undef, [$x,$y+$h]) );
    $self->dialog_settings->SetIcon(get_default_icon());
    $self->dialog_settings->slideshow_interval( $self->config->Read('slideshow_interval') );
    $self->dialog_settings->default_image_custom( $self->config->Read('default_image_custom') );
    $self->dialog_settings->default_image_path( $self->config->Read('default_image_path') );
    $self->dialog_settings->image_bgcolor( $self->config->Read('image_bgcolor') );
    $self->dialog_settings->image_cache_onoff( $self->config->Read('image_cache_onoff') );
    
    if ($self->dialog_settings->ShowModal == wxID_OK) {
        $self->config->Write(slideshow_interval => $self->dialog_settings->slideshow_interval);
        if ($self->frame->slideshow) {
            $self->frame->stop_slideshow_timer;
            $self->frame->start_slideshow_timer;
        }
        $self->config->Write(default_image_custom => $self->dialog_settings->default_image_custom);
        $self->config->Write(default_image_path => $self->dialog_settings->default_image_path);
        $self->config->Write(image_bgcolor => $self->dialog_settings->image_bgcolor);
        $self->config->Write(image_cache_onoff => $self->dialog_settings->image_cache_onoff);
        
        # 初期画面が変更された時に画像を何も読み込んでなければ即座に初期画面を変更する
        if ($self->store->count == 0) {
            $self->frame->draw_image( get_default_image() );
        }
        # または背景色が変更された際は再描画する
        elsif ($self->dialog_settings->{image_bgcolor_changed}) {
            $self->frame->draw_image($self->store->get);
        }
        
        $self->config->Flush;
    }
    
    $self->dialog_settings->Destroy();
}

sub show_dialog_url {
    my $self = shift;
    
    my ($x, $y) = $self->frame->GetPositionXY();
    my ($w, $h) = $self->frame->GetSizeWH();
    
    $h += 24 if $^O ne 'MSWin32';
    $self->dialog_url( NNPV::Dialog::Url->new(undef, undef, undef, [$x,$y+$h]) );
    $self->dialog_url->SetIcon(get_default_icon());
    
    if ($self->dialog_url->ShowModal == wxID_OK) {
        my $url = $self->dialog_url->text_ctrl_url;
        if ($url and defined(my $file = url_get($url))) {
            $self->load_image([{ path => $file, url => $url }]);
            $self->frame->Raise();
        }
    }
    
    $self->dialog_url->Destroy();
}

sub run {
    my $self = shift;
    
    $self->update_status_bar;
    
    $self->app->SetTopWindow($self->frame);
    $self->frame->Show(1);
    
    $self;
}

sub load_image {
    my $self  = shift;
    my $files = shift;
    NNPV::ImageLoader::load_image($files);
}

sub update_status_bar {
    my $self = shift;
    my $prefix = shift;
    my $suffix = shift;
    
    my $num_all = sprintf("%5d", $self->store->count);
    my $current_index = sprintf("%5d", $self->store->index + 1);
    my $current_info;
    
    if ($self->store->count > 0) {
        $current_info = $self->store->get->{path};
        
        my $url = $self->store->get->{url};
        if (defined $url) {
            $current_info = $url;
        }
        $self->frame->status_bar->SetStatusText("${prefix} [${current_index}/${num_all}] ${current_info} ${suffix}");
    }
    else {
        $self->frame->status_bar->SetStatusText("${prefix} 画像がありません ${suffix}");
    }
    
}

sub init_shuffle_table {
    my $self = shift;
    
    my $array = [0 .. $self->store->max];
    my $len = scalar(@$array);
    
    for (my $i = $len - 1; $i >= 0; --$i) {
        my $j = int(rand($i + 1));
        next if($i == $j);
        @$array[$i, $j] = @$array[$j, $i];
    }
    $self->shuffle_table($array);
    $self->shuffle_index(-1);
}

sub image_copy {
    my $self = shift;
    
    if (defined(my $data = $self->store->get)) {
        my $obj = Wx::DataObjectComposite->new;
        
        $obj->Add( Wx::TextDataObject->new( $data->{url} || $data->{path} ) );
        $obj->Add( Wx::BitmapDataObject->new( $data->{obj} ), 1 );
        wxTheClipboard->Open;
        wxTheClipboard->SetData( $obj );
        wxTheClipboard->Close;
    }
}

sub image_get {
    my $self = shift;
    my $index = shift;
    
    if ($self->frame->shuffle and $self->store->count >= 3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        my $index = $self->shuffle_table->[$self->shuffle_index];
    }
    if (defined(my $data = $self->store->get($index))) {
        $self->frame->draw_image($data);
        $self->update_status_bar;
    }
}

sub image_prev {
    my $self = shift;
    
    my $data = undef;
    if ($self->frame->shuffle and $self->store->count >= 3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        my $max = scalar @{$self->shuffle_table} - 1;
        if ($self->shuffle_index > 0) {
            $self->shuffle_index( $self->shuffle_index - 1 );
        }
        else {
            $self->shuffle_index($max);
        }
        $data = $self->store->get($self->shuffle_table->[$self->shuffle_index]);
    }
    else {
        $data = $self->store->prev;
    }
    if (defined $data) {
        $self->frame->draw_image($data);
        $self->update_status_bar;
    }
}

sub image_next {
    my $self = shift;
    
    my $data = undef;
    if ($self->frame->shuffle and $self->store->count >= 3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        my $max = scalar @{$self->shuffle_table} - 1;
        if ($self->shuffle_index < $max) {
            $self->shuffle_index( $self->shuffle_index + 1 );
        }
        else {
            $self->shuffle_index(0);
        }
        $data = $self->store->get($self->shuffle_table->[$self->shuffle_index]);
    }
    else {
        $data = $self->store->next;
    }
    if (defined $data) {
        $self->frame->draw_image($data);
        $self->update_status_bar;
    }
}

sub image_first {
    my $self = shift;
    
    my $data = undef;
    if ($self->frame->shuffle and $self->store->count >= 3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        $data = $self->store->get($self->shuffle_table->[$self->shuffle_index(0)]);
    }
    else {
        $data = $self->store->first;
    }
    if (defined $data) {
        $self->frame->draw_image($data);
        $self->update_status_bar;
    }
}

sub image_last {
    my $self = shift;
    
    my $data = undef;
    if ($self->frame->shuffle and $self->store->count >= 3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        my $max = scalar @{$self->shuffle_table} - 1;
        $data = $self->store->get($self->shuffle_table->[$self->shuffle_index($max)]);
    }
    else {
        $data = $self->store->last;
    }
    if (defined $data) {
        $self->frame->draw_image($data);
        $self->update_status_bar;
    }
}

sub image_delete {
    my $self = shift;
    
    if (defined(my $count = $self->store->delete)) {
        my $data;
        if ($count == 0) {
            $data = get_default_image();
        }
        else {
            $data = $self->store->get;
        }
        $self->frame->draw_image($data);
        $self->update_status_bar("1件削除されました");
    }
}

sub image_delete_all {
    my $self = shift;
    
    if (defined(my $count = $self->store->delete_all)) {
        my $data = get_default_image();
        $self->frame->draw_image($data);
        $self->update_status_bar("全件削除されました");
    }
}

sub toggle_slideshow {
    my $self = shift;
    
    if ($self->frame->slideshow) {
        $self->config->Write(slideshow_onoff => 0);
        $self->frame->slideshow(0);
        $self->frame->status_bar->SetStatusText("",1);
        $self->frame->stop_slideshow_timer;
    }
    else {
        $self->config->Write(slideshow_onoff => 1);
        $self->frame->slideshow(1);
        $self->frame->status_bar->SetStatusText("スライドショー",1);
        $self->frame->start_slideshow_timer;
    }
    $self->frame->slideshow;
}

sub toggle_shuffle {
    my $self = shift;
    
    if ($self->frame->shuffle) {
        $self->config->Write(shuffle_onoff => 0);
        $self->frame->status_bar->SetStatusText("",2);
        $self->frame->shuffle(0);
    }
    else {
        $self->config->Write(shuffle_onoff => 1);
        $self->frame->status_bar->SetStatusText("シャッフル",2);
        $self->frame->shuffle(1);
    }
    $self->frame->shuffle;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
