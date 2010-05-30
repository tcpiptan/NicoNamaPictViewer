package NNPV::FileSystem::Win32;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::Controller;
use Win32::API ();
use Win32::Unicode::Native;

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
    
    my $c = NNPV::Controller->instance;
    
    my $filesize = file_size($file);
    my $fh = Win32::Unicode::File->new(rb => $file) or $c->frame->status_bar->SetStatusText("ファイルが開けません [${file}]");
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

sub get_config_dir {
    my $self = shift;
    
    use Win32 qw(CSIDL_LOCAL_APPDATA);
    my $appdata = Win32::GetFolderPath(CSIDL_LOCAL_APPDATA, 1);
    if (file_type(d => $appdata)) {
        my $config_dir = File::Spec->catdir($appdata, $NNPV::APPSHORTNAME);
        if (file_type(d => $config_dir)) {
            return $config_dir;
        }
        elsif (mkdir($config_dir)) {
            return $config_dir;
        }
    }
}

sub is_dir {
    my $self = shift;
    my $path = shift;
    
    file_type(d => $path);
}

sub can_read {
    my $self = shift;
    my $path = shift;
    
    file_type(f => $path) and file_size($path) > 0;
}

sub open_dir {
    my $self = shift;
    
    $_[0] = Win32::Unicode::Dir->new;
    $_[0]->open($_[1]);
}

sub read_dir {
    my $self = shift;
    
    return ($_[0]->fetch);
}

sub close_dir {
    my $self = shift;
    
    $_[0]->close;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
