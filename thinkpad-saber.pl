# ThinkPad Saber
# Copyright 2006 Tatsuhiko Miyagawa miyagawa at gmail.com
# License: Same as Perl (GPL or Artistic)

use strict;
use Cwd;
use File::Spec;
use Win32API::File qw(:ALL);
use Win32::GUI ();
use Win32::Sound;
use Time::HiRes qw(gettimeofday sleep);
use List::Util qw(max min);
use Getopt::Long;

our $VERSION = "0.23";

GetOptions('--debug', \my $debug, '--threshold=s' => \my $threshold, "--help" => \my $help);
Getopt::Long::Configure("bundling"); # allows -d -t

if ($help) {
    print <<USAGE;
Usage: thinkpad-saber --debug --threshold=THRESHOLD

Options:
  --debug     print out debug message
  --threshold set threshold to play sound. (Defaults to 3.0)
              Increasing this value means you have to shake your TP faster. 
USAGE
    exit;
}

my $cwd = cwd;
$threshold ||= 3.0;

# dummy main window
my $main = Win32::GUI::Window->new(
    -name => 'Main',
    -text => 'ThinkPad Saber',
    -width => 200,
    -height => 200,
);

my $icon_file = $INC{"PAR.pm"}
    ? do { 
        my($fh, $is_new, $fn) = PAR::_tempfile("tpsaber.ico");
        my $data = PAR::read_file("resources/tpsaber.ico");
        print $fh $data;
        close $fh;
        $fn;
    } : "resources/tpsaber.ico";

my $icon = Win32::GUI::Icon->new($icon_file);
my $notify_icon = $main->AddNotifyIcon(
    -name => 'NI', -id => 1,
    -icon => $icon, -tip => 'ThinkPad Saber',
);

my $popup = Win32::GUI::Menu->new(
    "" => "SystemMenu",
    ">&Exit" => "Exit",
); 

sub NI_RightClick {
    my($x, $y) = Win32::GUI::GetCursorPos();
    $main->TrackPopupMenu($popup->{SystemMenu}, $x, $y);
    -1;
}

sub Exit_Click {
    Win32::Sound::Play('sound/off0.wav');
    exit;
}

sub get_pos {
    my $file = createFile("//./ShockMgr", "r ke") or die "Can't get ShockMgr device";
    DeviceIoControl($file, 0x733fc, [], 0, my($buf), 0x24, my($bytes), []);
    my @data = unpack "x4s*", $buf;
    return @data[1, 0];
}

# main program
Win32::Sound::Volume(65535, 65535);
Win32::Sound::Play('sound/start0.wav');

Win32::Sound::Play('sound/idle1.wav', SND_LOOP|SND_ASYNC);

my $depth = 8;

my(@xhist, @yhist);

for (1..$depth) {
    my($x, $y) = get_pos;
    push @xhist, $x;
    push @yhist, $y;
}

my $curr = 0;
my $mode = 1; # 1 = UP, 0 = DOWN

while (my($x, $y) = get_pos) {
    shift @xhist; shift @yhist; 
    push @xhist, $x; push @yhist, $y;

    my $xdev = stddev(@xhist);
    my $ydev = stddev(@yhist);

    my $dev = max($xdev, $ydev);
    if ($mode == 1) {
        if ($dev > $curr) {
            $curr = $dev;
        } else {
            if ($dev > $threshold) {
                play_sound($dev);
            }
            $mode = 0;
        }
    } else {
        if ($dev > $curr) {
            $curr = $dev;
            $mode = 1;
        } else {
            $curr = $dev;
        }
    }
    
    warn "$mode $dev" if $debug;
    Win32::GUI::DoEvents();
    
    my $idle = int(rand 100) % 2 ? 1 :0;
    Win32::Sound::Play("sound/idle$idle.wav", SND_NOSTOP|SND_LOOP|SND_ASYNC);
    sleep 0.05;
}

my %par_tmp;

sub play_sound {
    my $volume = shift;
    
    my $hit = $volume > 10 ? "hit" : "swing";
    my $num = int rand ($hit ? 5 : 8);
    my $filename = "$hit$num.wav";
#    $volume = int(65535 * min($volume / 15, 1));
    warn "playing $filename in $volume" if $debug;
#    Win32::Sound::Volume($volume);
    Win32::Sound::Play(File::Spec->catfile($cwd, "sound", $filename), SND_ASYNC);
}

sub stddev(@) {
    my $sum=0;
    my $sumsq=0;
    my $n=$#_+1;
    for my $v (@_) {
	$sum += $v;
	$sumsq += $v*$v;
    }
    return sqrt($n*$sumsq - $sum*$sum)/($n*($n-1));
}

