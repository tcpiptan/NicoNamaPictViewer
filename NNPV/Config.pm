package NNPV::Config;

# ＵＴＦ－８

use NNPV::CommonSense;
use NNPV::FileSystem::Functions;

use Wx qw(:everything);

use base qw(Exporter);

our @EXPORT = qw(
    config_dir
);

sub config_dir { get_config_dir }

sub init {
    my $config_file = File::Spec->catfile(get_config_dir, $NNPV::APPSHORTNAME . '.ini');
    my $new = not can_read($config_file);
    
    Wx::ConfigBase::Set(
        Wx::FileConfig->new(
            undef,
            undef,
            $config_file,
            undef,
            wxCONFIG_USE_LOCAL_FILE
        )
    );
    
    my $config = Wx::ConfigBase::Get;
    
    $config->Write(slideshow_onoff      => $new ? 0         : 0  + $config->Read('slideshow_onoff'));
    $config->Write(slideshow_interval   => $new ? 10        : 0  + $config->Read('slideshow_interval'));
    $config->Write(shuffle_onoff        => $new ? 0         : 0  + $config->Read('shuffle_onoff'));
    $config->Write(default_image_custom => $new ? 0         : 0  + $config->Read('default_image_custom'));
    $config->Write(default_image_path   => $new ? ''        : '' . $config->Read('default_image_path'));
    $config->Write(image_bgcolor        => $new ? '#000000' : '' . $config->Read('image_bgcolor'));
    $config->Write(image_cache_onoff    => $new ? 1         : 0  + $config->Read('image_cache_onoff'));
    
    $config->Flush;
    $config;
}

1;
