package NNPV::FileSystem::Functions;

use NNPV::CommonSense;
use NNPV::FileSystem;

use base qw(Exporter);

our @EXPORT = qw(
    is_image
    mimetype
    get_config_dir
    is_dir
    can_read
    decode_argv
    open_dir
    read_dir
    close_dir
);

foreach my $meth (@EXPORT) {
    my $sub = NNPV::FileSystem->can($meth);
    no strict 'refs';
    *{$meth} = sub {&$sub('NNPV::FileSystem', @_)};
}


1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
