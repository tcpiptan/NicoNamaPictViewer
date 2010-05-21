package NNPV::Controller;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::ImageStore;
use NNPV::ImageLoader;
use NNPV::Frame;

use base qw(Class::Singleton Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(app frame store) );

sub init {
    $NNPV::ImageLoader::USE_WX_PERL_IMAGICK = 1;
    Wx::InitAllImageHandlers();
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
}

sub init_frame {
    my $self = shift;
    
    $self->frame( NNPV::Frame->new );
    $self->frame->draw_image( get_default_image() );
    $self->frame->Fit();
    
    $self->frame;
}

sub run {
    my $self = shift;
    
    $self->update_status_bar;
    
    $self->app->SetTopWindow($self->frame);
    $self->frame->Show(1);
    
    $self;
}

sub load_image {
    my $self = shift;
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
    my $current_file;
    
    if ($self->store->count > 0) {
        $current_file = $self->store->get->{path};
        $self->frame->status_bar->SetStatusText("${prefix} [${current_index}/${num_all}] ${current_file} ${suffix}");
    }
    else {
        $self->frame->status_bar->SetStatusText("${prefix} 画像がありません ${suffix}");
    }
    
}

sub image_get {
    my $self = shift;
    my $index = shift;
    
    if (defined(my $bitmap = $self->store->get($index))) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_prev {
    my $self = shift;
    
    if (defined(my $bitmap = $self->store->prev)) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_next {
    my $self = shift;
    
    if (defined(my $bitmap = $self->store->next)) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_first {
    my $self = shift;
    
    if (defined(my $bitmap = $self->store->first)) {
        $self->frame->draw_image($bitmap);
        $self->update_status_bar;
    }
}

sub image_last {
    my $self = shift;
    
    if (defined(my $bitmap = $self->store->last)) {
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

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
