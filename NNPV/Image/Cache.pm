package NNPV::Image::Cache;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV;
use NNPV::Config;
use NNPV::FileSystem::Functions;
use Wx qw(:everything);
use Digest::SHA1 qw(sha1_hex);
use Encode;
use File::Basename;

my $digest_version = 1;

use base qw(Exporter);

our @EXPORT = qw(
    cache_dir
    file_digest
    cache_load
    cache_store
);

sub cache_dir()    { File::Spec->catdir(config_dir, 'cache') }
sub file_digest($) { sha1_hex($digest_version, encode_utf8(shift), $NNPV::IMAGE_WIDTH, $NNPV::IMAGE_HEIGHT) }

sub cache_path($)  {
    my $path = shift;
    
    my $digest = file_digest($path);
    $digest =~ /^(...)(...)/;
    
    File::Spec->catfile(cache_dir, $1, $2, $digest);
}

sub cache_load($) {
    my $path = shift;
    
    my $cache_path = cache_path $path;
    return undef unless can_read $cache_path;
    
    my $bitmap = Wx::Bitmap->new($cache_path, wxBITMAP_TYPE_PNG);
    return undef unless $bitmap and $bitmap->IsOk;
    
    $bitmap;
}

sub cache_store($$) {
    my $bitmap = shift;
    my $path = shift;
    
    mkdir(cache_dir) unless is_dir(cache_dir);
    
    my $digest_path = cache_path $path;
    my $digest_dir   = dirname $digest_path;
    my $digest_dir2  = dirname $digest_dir;
    
    mkdir($digest_dir2) unless is_dir($digest_dir2);
    mkdir($digest_dir)  unless is_dir($digest_dir);
    
    $bitmap->SaveFile($digest_path, wxBITMAP_TYPE_PNG);
}

1;
