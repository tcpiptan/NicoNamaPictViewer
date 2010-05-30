package NNPV::Util;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::FileSystem::Functions;
use Wx qw(:everything);

use base qw(Exporter);

our @EXPORT = qw(
    msg_error
    resource_path
);

sub msg_error {
    my $msg = shift;
    my $title = shift || $NNPV::APPNAME;
    Wx::MessageBox($msg, $title, wxOK|wxCENTRE|wxICON_ERROR);
}

sub resource_path($) {
    my $file = shift;
    
    my $path = undef;
    if ($NNPV::PDK and defined(&PerlApp::extract_bound_file)){
        my $bind = PerlApp::extract_bound_file($file);
        $path = $bind if defined $bind;
    }
    elsif ($NNPV::PAR and defined $ENV{PAR_TEMP}) {
        my $bind = File::Spec->catfile($ENV{PAR_TEMP}, 'inc', $path);
        $path if can_read($bind);
    }
    elsif (not File::Spec->file_name_is_absolute($file)) {
        $path = File::Spec->rel2abs($file);
    }
    $path;
}

1;
