package NNPV::Controller;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::ImageStore;
use NNPV::ImageLoader;
use NNPV::Frame;
use NNPV::Dialog::Settings;
use NNPV::Dialog::Url;
use NNPV::FileSystem::Functions;

use FindBin;
use Wx qw(wxCONFIG_USE_LOCAL_FILE wxID_OK wxTIMER_CONTINUOUS);

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
    
    my $file = abspath('nnpv.ini');
    
    my $config = Wx::FileConfig->new(
        $self->app->GetAppName() ,
        $self->app->GetVendorName() ,
        $file,
        '',
        wxCONFIG_USE_LOCAL_FILE
    );
    Wx::ConfigBase::Set($config);
    $self->config( Wx::ConfigBase::Get );
    
    unless (-e $file) {
        $self->config->Write(slideshow_onoff    =>  0);
        $self->config->Write(slideshow_interval => 10);
        $self->config->Write(shuffle_onoff      =>  0);
        $self->config->Flush;
    }
    
    $self->config;
}

sub init_frame {
    my $self = shift;
    
    $self->frame( NNPV::Frame->new );
    $self->frame->slideshow( $self->config->Read('slideshow_onoff') +0 );
    if ($self->frame->slideshow) {
        $self->frame->menuitem_slideshow->Check(1);
        $self->frame->status_bar->SetStatusText("スライドショー",1);
        $self->frame->start_timer;
    }
    $self->frame->shuffle( $self->config->Read('shuffle_onoff') +0 );
    if ($self->frame->shuffle) {
        $self->frame->menuitem_shuffle->Check(1);
        $self->frame->status_bar->SetStatusText("シャッフル",2);
    }
    $self->frame->draw_image( get_default_image() );
    $self->frame->Fit;
    $self->frame->Layout;
    
    $self->frame;
}

sub init_settings {
    my $self = shift;
    
    my ($x, $y) = $self->frame->GetPositionXY();
    my ($w, $h) = $self->frame->GetSizeWH();
    
    $h += 24 if $^O ne 'MSWin32';
    $self->dialog_settings( NNPV::Dialog::Settings->new(undef, undef, undef, [$x,$y+$h]) );
    $self->dialog_settings->SetIcon(get_default_icon());
    $self->dialog_settings->slideshow_interval( $self->config->Read('slideshow_interval') );
    
    if ($self->dialog_settings->ShowModal == wxID_OK) {
        $self->config->Write(slideshow_interval => $self->dialog_settings->slideshow_interval);
        if ($self->frame->slideshow) {
            $self->frame->stop_timer;
            $self->frame->start_timer;
        }
    }
    
    $self->dialog_settings->Destroy();
}

sub init_url {
    my $self = shift;
    
    my ($x, $y) = $self->frame->GetPositionXY();
    my ($w, $h) = $self->frame->GetSizeWH();
    
    $h += 24 if $^O ne 'MSWin32';
    $self->dialog_url( NNPV::Dialog::Url->new(undef, undef, undef, [$x,$y+$h]) );
    $self->dialog_url->SetIcon(get_default_icon());
    
    if ($self->dialog_url->ShowModal == wxID_OK) {
        my $url = $self->dialog_url->text_ctrl_url;
        if (defined(my $file = get($url))) {
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
    
    my $num_backup = $self->store->count;
    my $num = NNPV::ImageLoader::load_image($files);
    if ($num > 0) {
        # 元が0個だったら再描画
        #if ($num_backup == 0) {
        #    $self->frame->draw_image($self->store->get(0));
        #}
        
        # 追加されたファイルのうち最初のファイルを描画
        $self->frame->draw_image($self->store->get($num_backup));
        
        $self->update_status_bar("${num}件追加されました");
    }
    
    $num;
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

sub image_get {
    my $self = shift;
    my $index = shift;
    
    if ($self->frame->shuffle and $self->store->count >=3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        my $index = $self->shuffle_table->[$self->shuffle_index];
    }
    if (defined(my $bitmap = $self->store->get($index))) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_prev {
    my $self = shift;
    
    my $bitmap = undef;
    if ($self->frame->shuffle and $self->store->count >=3) {
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
        $bitmap = $self->store->get($self->shuffle_table->[$self->shuffle_index]);
    }
    else {
        $bitmap = $self->store->prev;
    }
    if (defined $bitmap) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_next {
    my $self = shift;
    
    my $bitmap = undef;
    if ($self->frame->shuffle and $self->store->count >=3) {
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
        $bitmap = $self->store->get($self->shuffle_table->[$self->shuffle_index]);
    }
    else {
        $bitmap = $self->store->next;
    }
    if (defined $bitmap) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_first {
    my $self = shift;
    
    my $bitmap = undef;
    if ($self->frame->shuffle and $self->store->count >=3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        $bitmap = $self->store->get($self->shuffle_table->[$self->shuffle_index(0)]);
    }
    else {
        $bitmap = $self->store->first;
    }
    if (defined $bitmap) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_last {
    my $self = shift;
    
    my $bitmap = undef;
    if ($self->frame->shuffle and $self->store->count >=3) {
        if (scalar @{$self->shuffle_table} ne $self->store->count) {
            $self->init_shuffle_table;
        }
        my $max = scalar @{$self->shuffle_table} - 1;
        $bitmap = $self->store->get($self->shuffle_table->[$self->shuffle_index($max)]);
    }
    else {
        $bitmap = $self->store->last;
    }
    if (defined $bitmap) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_delete {
    my $self = shift;
    
    if (defined(my $count = $self->store->delete)) {
        my $bitmap;
        if ($count == 0) {
            $bitmap = get_default_image();
        }
        else {
            $bitmap = $self->store->get;
        }
        $self->frame->draw_image($bitmap);
        $self->update_status_bar("1件削除されました");
    }
}

sub image_delete_all {
    my $self = shift;
    
    if (defined(my $count = $self->store->delete_all)) {
        my $bitmap = get_default_image();
        $self->frame->draw_image($bitmap);
        $self->update_status_bar("全件削除されました");
    }
}

sub toggle_slideshow {
    my $self = shift;
    
    if ($self->frame->slideshow) {
        $self->config->Write(slideshow_onoff => 0);
        $self->frame->slideshow(0);
        $self->frame->status_bar->SetStatusText("",1);
        $self->frame->stop_timer;
    }
    else {
        $self->config->Write(slideshow_onoff => 1);
        $self->frame->slideshow(1);
        $self->frame->status_bar->SetStatusText("スライドショー",1);
        $self->frame->start_timer;
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
