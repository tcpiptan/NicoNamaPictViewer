@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl
#line 15

use Getopt::Long;
use NNPV;

my $gui = '--gui';
my $debug;
my $options = GetOptions(
    "debug" => \$debug,
);
$gui = '' if $debug;

my $version = $NNPV::VERSION;
my $appname = $NNPV::APPNAME;
my $vendor  = $NNPV::VENDORNAME;
my $author  = $NNPV::AUTHOR;
my $year    = [localtime(time)]->[5] + 1900;
my $since   = ($year > 2010 ? '2010-'.$year : 2010);
my $imdir   = 'D:/Program Files/ImageMagick-6.6.2-Q16';
my $exe     = $NNPV::EXE;

my $bat =<<"__EOD__";
perlapp
--add Wx::DND;constants;utf8;File::MMagic;Encode::JP;NNPV::FileSystem::Win32
--bind resources/Default.jpg[file=resources/Default.jpg,extract,mode=444]
--bind resources/NNPV.ico[file=resources/NNPV.ico,extract,mode=444]
--bind auto/Win32/Unicode/Unicode.dll[file=D:/strawberry/perl/site/lib/auto/Win32/Unicode/Unicode.dll,extract,mode=444]
--bind wxmain.dll[file=D:/Perl/site/lib/auto/Wx/Wx.dll,extract,mode=444]
--bind Magick.dll[file=D:/Perl/site/lib/auto/Image/Magick/Magick.dll,extract,mode=444]
--info "CompanyName=${vendor};FileVersion=${version};InternalName=${appname};LegalCopyright=${author} ${since} All Rights Reserved.;OriginalFilename=${appname};ProductName=${appname};ProductVersion=${version}"
--manifest resources/nnpv.exe.manifest
--icon resources/NNPV.ico
--norunlib
--nologo
--force
--exe ${exe} ${gui} NNPV.pl
__EOD__

print $bat;
`$bat`;

print "\nDone.\n";
print "run $exe? [y/n]: ";
my $ans;
while($ans=<>){
    chomp $ans;
    if ($ans =~ /^[yn]$/i) { last; }
    else { print "run $exe? [y/n]: " and next; }
}

if ($ans =~ /^y$/i) {
    `$exe`;
    print "Please press any key...";
    <>;
}

__END__
:endofperl
