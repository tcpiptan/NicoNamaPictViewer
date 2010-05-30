package NNPV::FileSystem;

# ＵＴＦ－８

use NNPV::CommonSense;

my $module = $^O eq 'MSWin32' ? 'Win32' : 'Unix';

require "NNPV/FileSystem/$module.pm";
our @ISA = ("NNPV::FileSystem::$module");

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
