package NNPV::FileSystem::Unix;

# ＵＴＦ－８

use NNPV::CommonSense;
use File::Spec;
use File::MMagic;

sub new { bless {}, shift }

sub abspath {
    my $self = shift;
    my $file = shift;
    
    my $bound_file = undef;
    if (defined(&PerlApp::extract_bound_file)){
        $bound_file = PerlApp::extract_bound_file($file);
        $file = $bound_file if defined $bound_file;
    }
    elsif (defined $ENV{PAR_TEMP}) {
        my $test = File::Spec->catfile($ENV{PAR_TEMP}, 'inc', $file);
        $file = $test if -e $test;
    }
    if (!defined($bound_file)) {
        unless (File::Spec->file_name_is_absolute($file)) {
            $file = File::Spec->rel2abs($file);
        }
    }
    
    $file;
}

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

sub _scan_files {
    my $self = shift;
    my $files = shift;
    my $results = shift;
    my $count_ref = shift;
    
    my $controller = NNPV::Controller->instance;
    
    for my $file (@$files) {
        if (-d -x $file) {
            opendir(my $dh, $file) or $controller->frame->status_bar->SetStatusText("ディレクトリが開けません");
            my @children = sort
                           map { File::Spec->catfile($file, $_) }
                           grep { !/^\.{1,2}$/ }
                           readdir $dh;
            closedir $dh;
            $self->_scan_files(\@children, $results, $count_ref);
        }
        elsif (-f -r -s $file) {
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
