package NNPV::FileSystem::Unix;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use File::Spec;
use File::MMagic;
use LWP::UserAgent;

sub new { bless {}, shift }

sub is_image {
    my $self = shift;
    my $file = shift;
    
    my $type = $self->mimetype($file);
    
    return ($type =~ m@^image/(bmp|gif|pjpeg|jpeg|x-png|png)$@);
}

sub mimetype {
    my $self = shift;
    my $file = shift;
    
    File::MMagic->new->checktype_filename($file);
}

sub get_config_dir {
    my $self = shift;
    
    if (-d $ENV{HOME}) {
        my $profile_dir = File::Spec->catdir($ENV{HOME}, '.' . $NNPV::APPSHORTNAME);
        if (-d $profile_dir) {
            return $profile_dir;
        }
        elsif (mkdir($profile_dir)) {
            return $profile_dir;
        }
    }
}

sub is_dir {
    my $self = shift;
    my $path = shift;
    
    -d -x $path;
}

sub can_read {
    my $self = shift;
    my $path = shift;
    
    -f -r -s $path;
}

sub open_dir {
    my $self = shift;
    
    opendir($_[0], $_[1]);
}

sub read_dir {
    my $self = shift;
    
    return (readdir $_[0]);
}

sub close_dir {
    my $self = shift;
    
    closedir $_[0];
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
