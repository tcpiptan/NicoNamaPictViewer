package NNPV::CommonSense;

# ＵＴＦ－８

# exclude 'features' from 'common::sense'

sub import {
   # use warnings
   ${^WARNING_BITS} ^= ${^WARNING_BITS} ^ "\xfc\x3f\x33\x00\x0f\xf3\x0f\xc0\xf0\xfc\x33\x00";
   # use strict, use utf8;
   $^H |= 0x800600;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
