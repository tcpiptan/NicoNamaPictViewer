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

sub _opendir {
    my $self = shift;
    
    opendir($_[0], $_[1]);
}

sub _readdir {
    my $self = shift;
    
    return (readdir $_[0]);
}

sub _closedir {
    my $self = shift;
    
    closedir $_[0];
}

sub scan_files {
    my $self = shift;
    my $files = shift;
    my $results = shift;
    my $count_ref = shift;
    
    my $c = NNPV::Controller->instance;
    
    for my $file (@$files) {
        if ($self->is_dir($file->{path})) {
            my $config_dir = $self->get_config_dir;
            next if $file->{path} =~ /^$config_dir/;
            $self->_opendir(my $dh, $file->{path}) or next;
            my @children = ();
            for my $f ($self->_readdir($dh)) {
                next if $f =~ /^\.{1,2}$/;
                my $struct = {%$file};
                $struct->{path} = File::Spec->catfile($file->{path}, $f);
                push @children, $struct;
            }
            $self->_closedir($dh);
            @children = sort { $a->{path} <=> $b->{path} } @children;
            $self->scan_files(\@children, $results, $count_ref);
        }
        elsif ($self->can_read($file->{path})) {
            if ($self->is_image($file->{path})) {
                ${$count_ref}++;
                my $num = sprintf("%5d", ${$count_ref});
                $c->frame->status_bar->SetStatusText("画像ファイルを数えています... [${$count_ref}]");
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
