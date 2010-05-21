package NNPV::FileSystem::Common;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::FileSystem;
use File::Spec;
use File::MMagic;

use base qw(Exporter);

our @EXPORT = qw(
    abspath
    is_image
);

sub abspath {
    my $file = shift;
    
    print "in abspath\n";
    my $bound_file = undef;
    if (defined(&PerlApp::extract_bound_file)){
        $bound_file = PerlApp::extract_bound_file($file);
        $file = $bound_file if defined $bound_file;
    }
    if (!defined($bound_file)) {
        my $test = File::Spec->catfile($ENV{PAR_TEMP}, 'inc', $file);
        $file = $test if -e $test;
        
        unless (File::Spec->file_name_is_absolute($file)) {
            $file = File::Spec->rel2abs($file);
        }
    }
    $file;
}

sub is_image {
    my $file = shift;
    my $type = mimetype($file);
    return ($type =~ m@^image/(bmp|gif|pjpeg|jpeg|x-png|png)$@);
}

1;
