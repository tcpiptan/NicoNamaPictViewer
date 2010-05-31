package NNPV::Frame::Constants;

# ＵＴＦ－８

use NNPV::CommonSense;
use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(Exporter);

our @EXPORT = qw(
    MENU_FILE_OPEN
    MENU_IMAGE_PREV
    MENU_IMAGE_NEXT
    MENU_IMAGE_FIRST
    MENU_IMAGE_LAST
    MENU_IMAGE_DELETE
    MENU_IMAGE_DELETEALL
    MENU_IMAGE_0
    MENU_IMAGE_1
    MENU_IMAGE_2
    MENU_IMAGE_3
    MENU_IMAGE_4
    MENU_IMAGE_5
    MENU_IMAGE_6
    MENU_IMAGE_7
    MENU_IMAGE_8
    MENU_IMAGE_9
    MENU_IMAGE_SLIDESHOW
    MENU_IMAGE_SHUFFLE
    MENU_IMAGE_URL
    MENU_IMAGE_COPY
    MENU_OTHER_SETTINGS
    TIMER_IDLE
    TIMER_SLIDESHOW
    BUTTON_WGET
);

sub MENU_FILE_OPEN       () { 1001 };
sub MENU_IMAGE_PREV      () { 2001 };
sub MENU_IMAGE_NEXT      () { 2002 };
sub MENU_IMAGE_FIRST     () { 2003 };
sub MENU_IMAGE_LAST      () { 2004 };
sub MENU_IMAGE_DELETE    () { 2005 };
sub MENU_IMAGE_DELETEALL () { 2006 };
sub MENU_IMAGE_0         () { 2101 };
sub MENU_IMAGE_1         () { 2102 };
sub MENU_IMAGE_2         () { 2103 };
sub MENU_IMAGE_3         () { 2104 };
sub MENU_IMAGE_4         () { 2105 };
sub MENU_IMAGE_5         () { 2106 };
sub MENU_IMAGE_6         () { 2107 };
sub MENU_IMAGE_7         () { 2108 };
sub MENU_IMAGE_8         () { 2109 };
sub MENU_IMAGE_9         () { 2110 };
sub MENU_IMAGE_SLIDESHOW () { 2201 };
sub MENU_IMAGE_SHUFFLE   () { 2202 };
sub MENU_IMAGE_URL       () { 2301 };
sub MENU_IMAGE_COPY      () { 2401 };
sub MENU_OTHER_SETTINGS  () { 3001 };
sub TIMER_IDLE           () { 4001 };
sub TIMER_SLIDESHOW      () { 4002 };
sub BUTTON_WGET          () { 5001 };

1;
