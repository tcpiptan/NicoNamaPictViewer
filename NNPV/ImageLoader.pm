package NNPV::ImageLoader;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use NNPV::ImageStore;
use NNPV::Controller;
use NNPV::FileSystem::Functions;
use Wx qw(wxBITMAP_TYPE_ANY wxBITMAP_TYPE_ICO wxBLACK_BRUSH wxNullBitmap wxIMAGE_QUALITY_HIGH);

use base qw(Exporter);

our @EXPORT = qw(
    get_default_bitmap
    get_default_image
    get_default_icon
    load_image
    file_to_bitmap
    _test
);

our $USE_WX_PERL_IMAGICK;
our $IMAGE_WIDTH  = 512;
our $IMAGE_HEIGHT = 384;

our $DEFAULT_IMAGE = 'resources/Default.jpg';
our $DEFAULT_XPM   = 'resources/NNPV.ico';

sub init {
    eval { require Wx::Perl::Imagick; };
    if ($@) {
        $USE_WX_PERL_IMAGICK = 0;
    }
    else {
        $USE_WX_PERL_IMAGICK = 1;
        Wx::Perl::Imagick->import();
    }
}

sub get_default_bitmap {
    Wx::Bitmap->new($IMAGE_WIDTH, $IMAGE_HEIGHT);
}

sub get_default_image {
    my $default_image = abspath($DEFAULT_IMAGE);
    my $obj = file_to_bitmap($default_image);
    my $image = { path => $default_image, obj => $obj };
    
    $image;
}

sub get_default_icon {
    my $default_icon = abspath($DEFAULT_XPM);
    Wx::Icon->new($default_icon, wxBITMAP_TYPE_ICO);
}

sub load_image {
    my $_files = shift;
    
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
    
    my $controller = NNPV::Controller->instance;
    
    # 画像ファイルのみを数える
    my $scan_count = 0;
    _scan_files($files, my $scan_results = [], \$scan_count);
    
    my $converted = 0;
    if (scalar @$scan_results) {
        $converted = _convert_files($scan_results);
    }
    $converted;
}

sub file_to_bitmap {
    my $file = shift;
    
    return undef unless is_image($file);
    
    my $image = _obj($file);
    
    return undef unless $image;
    
    my $bitmap_dst = Wx::Bitmap->new($IMAGE_WIDTH, $IMAGE_HEIGHT);
    
    my $bitmap_src = _resize_to_bitmap($image);
    my $offset_x = int(($IMAGE_WIDTH  - $bitmap_src->GetWidth ) / 2);
    my $offset_y = int(($IMAGE_HEIGHT - $bitmap_src->GetHeight) / 2);
    
    my $dc_dst = Wx::MemoryDC->new();
    $dc_dst->SelectObject($bitmap_dst);
    $dc_dst->SetBackground(wxBLACK_BRUSH);
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
    
    my $controller = NNPV::Controller->instance;
    my $all_num = scalar @$files;
    $controller->frame->status_bar->SetStatusText("[  0%] 読み込み中です...");
    
    my $num = 0;
    my $converted = 0;
    for my $file (@$files) {
        
        $num++;
        
        my $per = sprintf("%3d", $num / $all_num * 100);
        my $info = $file->{path};
        if (defined $file->{url}) {
            $info = $file->{url};
        }
        $controller->frame->status_bar->SetStatusText("[${per}%] 読み込み中です... $info");
        my $image = file_to_bitmap($file->{path});
        if (_obj_ok($image)) {
            $converted++;
            $file->{obj} = $image;
            $controller->store->add($file);
        }
        else {
            $controller->frame->status_bar->SetStatusText("失敗1 [" . $file->{path} . "]");
        }
    }
    $controller->frame->draw_image( $controller->store->get );
    $converted;
}

sub _obj {
    my $file = shift;
    
    my $image;
    
    if ($USE_WX_PERL_IMAGICK) {
        $image = Wx::Perl::Imagick->new($file);
    }
    else {
        $image = Wx::Image->new($file, wxBITMAP_TYPE_ANY);
    }
    return undef unless (_obj_ok($image));
    
    $image;
}

sub _obj_ok {
    my $obj = shift; # Bitmap Object
    
    my $ok = undef;
    
    if ($USE_WX_PERL_IMAGICK) {
        $ok = $obj->Ok;
    }
    else {
        $ok = $obj->IsOk;
    }
    $ok;
}

sub _resize_to_bitmap {
    my $image = shift;
    
    my ($pict_width, $pict_height) = ($image->GetWidth, $image->GetHeight);
    my ($scale_width, $scale_height) = ($pict_width, $pict_height);
    
    my $rate = 1;
    my $offset_x = 0;
    my $offset_y = 0;
    
# if 文を有効にすると、拡大処理を行わない
#    if ($pict_width > $IMAGE_WIDTH or $pict_height > $IMAGE_HEIGHT) {
        my $rate_width  = $IMAGE_WIDTH  / $pict_width;
        my $rate_height = $IMAGE_HEIGHT / $pict_height;
        $rate = $rate_width > $rate_height ? $rate_height : $rate_width;
        $scale_width  *= $rate;
        $scale_height *= $rate;
#    }
    
    my $bitmap;
    if ($USE_WX_PERL_IMAGICK) {
        if ($rate != 1) {
            $image->Resize(width => $scale_width, height => $scale_height);
        }
        $bitmap = $image->ConvertToBitmap;
    }
    else {
        if ($rate != 1) {
            $image = $image->Scale($scale_width, $scale_height, wxIMAGE_QUALITY_HIGH);
        }
        $bitmap = Wx::Bitmap->new($image);
    }
    
    $bitmap;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
