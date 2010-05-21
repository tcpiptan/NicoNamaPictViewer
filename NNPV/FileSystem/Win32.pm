package NNPV::FileSystem::Win32;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Controller;
use Win32::Unicode;
use Win32::API ();

use base qw(NNPV::FileSystem::Unix);

use constant {
    FindMimeFromData => Win32::API->new('urlmon',   'FindMimeFromData', 'PPPNPNPN', 'N'),
    LocalLock        => Win32::API->new('kernel32', 'LocalLock',        'N',        'N'),
    LocalUnlock      => Win32::API->new('kernel32', 'LocalUnlock',      'N',        'N'),
    LocalFree        => Win32::API->new('kernel32', 'LocalFree',        'N',        'N'),
    RtlMoveMemory    => Win32::API->new('kernel32', 'RtlMoveMemory',    'PNN'),
};

sub mimetype {
    my $self = shift;
    my $file = shift;
    
    my $controller = NNPV::Controller->instance;
    
    my $filesize = file_size $file;
    my $fh = Win32::Unicode::File->new(rb => $file) or $controller->frame->status_bar->SetStatusText("ファイルが開けません [${file}]");
    $fh->read(my $filedata, $filesize);
    $fh->close;
    
    FindMimeFromData->Call(0, 0, $filedata, $filesize, 0, 0, my $ret = 0 x 8, 0);
    
    my $pointer = unpack("L", $ret);
    my $strdata = LocalLock->Call($pointer);
    
    # MIME-Type string buffer : 16 * 2
    # 下記が認識できれば十分な文字数
    # image/bmp
    # image/gif
    # image/pjpeg
    # image/jpeg
    # image/x-png
    # image/png
    # image/tiff
    my $size = 16 * 2 * Win32::API::Type->sizeof('WCHAR*');
    RtlMoveMemory->Call(my $output = " " x $size, $strdata, $size);
    
    LocalUnlock->Call($strdata);
    LocalFree->Call($strdata);
    
    # NULL文字までを切り出し
    $output =~ s/^((?:..)*?)(\x00\x00).*/$1/s;
    
    Win32::Unicode::Util::utf16_to_utf8($output);
}

sub _scan_files {
    my $self = shift;
    my $files = shift;
    my $results = shift;
    my $count_ref = shift;
    
    my $controller = NNPV::Controller->instance;
    
    for my $file (@$files) {
        if (file_type d => $file) {
            my $dh = Win32::Unicode::Dir->new;
            $dh->open($file) or $controller->frame->status_bar->SetStatusText("ディレクトリが開けません");
            my @children = ();
            for ($dh->fetch) {
                next if /^\.{1,2}$/;
                my $full_path = "$file\\$_";
                push @children, $full_path;
            }
            $dh->close;
            $self->_scan_files(\@children, $results, $count_ref);
        }
        elsif (file_type f => $file) {
            if ($self->is_image($file)) {
                ${$count_ref}++;
                my $num = sprintf("%5d", ${$count_ref});
                $controller->frame->status_bar->SetStatusText("画像ファイルを数えています... [${num}]");
                push @$results, $file;
            }
        }
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
