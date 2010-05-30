package NNPV::ImageLoader;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use NNPV::ImageStore;
use NNPV::Controller;
use NNPV::FileSystem::Functions;
use NNPV::Util;
use NNPV::Image::Cache;
use Wx qw(:everything);

use base qw(Exporter);

our @EXPORT = qw(
    get_default_image
    get_default_icon
    load_image
    get_bitmap_from_file
    url_get
    centering_bitmap
);

our $IMAGICK;

our $DEFAULT_IMAGE = 'resources/Default.jpg';
our $DEFAULT_ICON  = 'resources/NNPV.ico';

our $_queueing_on_queueing;
our @_queue;
our $_queue_sum;
our $_first_loaded_image_index;

sub init {
    eval { require Wx::Perl::Imagick; };
    if ($@) {
        $IMAGICK = 0;
    }
    else {
        $IMAGICK = 1;
        Wx::Perl::Imagick->import();
    }
}

sub get_default_image {
    my $path;
    my $bitmap;
    my $c = NNPV::Controller->instance;
    if ($c->config->Read('default_image_custom')) {
        $path = $c->config->Read('default_image_path');
        if (length($path) > 0 and can_read($path)) {
            $bitmap = get_bitmap_from_file($path);
        }
    }
    unless ($bitmap and $bitmap->IsOk) {
        $path = resource_path($DEFAULT_IMAGE);
        $bitmap = get_bitmap_from_file($path);
    }
    +{ path => $path, obj => $bitmap };
}

sub get_default_icon {
    Wx::Icon->new(resource_path($DEFAULT_ICON), wxBITMAP_TYPE_ICO);
}

sub load_image {
    my $_files = shift;
    
    # キューが全て捌けないうちに次のキューが追加されようとしている
    if (@_queue) {
        $_queueing_on_queueing = 1;
    }
    
    my $files = [];
    for my $file (@$_files) {
        if (ref $file eq 'HASH' and defined $file->{path}) {
            push @$files, $file;
        }
        else {
            push @$files, { path => $file };
        }
    }
    # ソート
    $files = [sort { $a->{path} <=> $b->{path} } @$files];
    
    # 画像ファイルのみを数える
    my $scan_count = 0;
    scan_files($files, my $scan_results = [], \$scan_count);
    
    my $converted = 0;
    if (scalar @$scan_results) {
        $converted = _convert_files($scan_results);
    }
    $converted;
}

sub get_bitmap_from_file {
    my $file = shift;
    
    return undef unless is_image($file);
    
    my $image;
    if ($IMAGICK) {
        $image = Wx::Perl::Imagick->new($file);
    }
    else {
        $image = Wx::Image->new($file, wxBITMAP_TYPE_ANY);
    }
    
    return undef unless $image;
    
    my ($pict_width,  $pict_height)  = ($image->GetWidth, $image->GetHeight);
    my ($scale_width, $scale_height) = ($pict_width,      $pict_height);
    
    my $rate_width  = $NNPV::IMAGE_WIDTH  / $pict_width;
    my $rate_height = $NNPV::IMAGE_HEIGHT / $pict_height;
    
    my $rate = $rate_width > $rate_height ? $rate_height : $rate_width;
    $scale_width  *= $rate;
    $scale_height *= $rate;
    
    my $bitmap;
    if ($IMAGICK) {
        $image->Resize(width => $scale_width, height => $scale_height) unless $rate == 1;
        $bitmap = $image->ConvertToBitmap;
    }
    else {
        $image = $image->Scale($scale_width, $scale_height, wxIMAGE_QUALITY_HIGH) unless $rate == 1;
        $bitmap = Wx::Bitmap->new($image);
    }
    
    $bitmap if $bitmap and $bitmap->IsOk;
}

sub url_get {
    my $url = shift;
    my $method = shift || 'GET';
    
    my $digest = file_digest $url;
    my $file = File::Spec->catfile(File::Spec->tmpdir, $digest);
    return $file if can_read($file);
    
    if ($url =~ m|^https?://|) {
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->agent('Mozilla');
        my $req = HTTP::Request->new($method => $url);
        my $res = $ua->request($req);
        if ($res->is_success) {
            my $type = $res->content_type;
            if ($type =~ m!^image/(bmp|gif|pjpeg|jpeg|x-png|png)$!) {
                open(my $fh, '>', $file);
                binmode $fh;
                print $fh $res->content;
                close $fh;
                return $file;
            }
            else {
                msg('画像のURLではありません。');
            }
        }
        else {
            msg('画像の取得に失敗しました。');
        }
    }
    else {
        msg('URLが不正です。');
    }
    
    return undef;
}

sub centering_bitmap {
    my $bitmap_src = shift;
    
    my $c = NNPV::Controller->instance;
    my $bgcolor = Wx::Colour->new( $c->config->Read('image_bgcolor') );
    my $brush = Wx::Brush->new($bgcolor, wxSOLID);
    
    my $bitmap_dst = Wx::Bitmap->new($NNPV::IMAGE_WIDTH, $NNPV::IMAGE_HEIGHT);
    
    my $offset_x = int(($NNPV::IMAGE_WIDTH  - $bitmap_src->GetWidth ) / 2);
    my $offset_y = int(($NNPV::IMAGE_HEIGHT - $bitmap_src->GetHeight) / 2);
    
    my $dc_dst = Wx::MemoryDC->new();
    $dc_dst->SelectObject($bitmap_dst);
    $dc_dst->SetBackground($brush);
    $dc_dst->Clear;
    
    my $dc_src = Wx::MemoryDC->new();
    $dc_src->SelectObject($bitmap_src);
    
    $dc_dst->Blit($offset_x, $offset_y, $bitmap_src->GetWidth, $bitmap_src->GetHeight, $dc_src, 0, 0);
    $dc_dst->SelectObject(wxNullBitmap);
    
    $dc_src->SelectObject(wxNullBitmap);
    
    $bitmap_dst;
}

sub _convert_files {
    my $files = shift;
    
    my $num_all = scalar @$files;
    $_queue_sum += $num_all;
    my $num = 0;
    for my $file (@$files) {
        $num++;
        
        # 前のキューが捌ける前に追加キュー要求が間に合った
        $_queueing_on_queueing = 0 if $_queueing_on_queueing and @_queue;
        
        push @_queue, { target => $file, num_all => $num_all, num => $num };
    }
    $num_all;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
