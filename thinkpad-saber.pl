# ThinkPad Saber
# Copyright 2006 Tatsuhiko Miyagawa miyagawa at gmail.com
# License: Same as Perl (GPL or Artistic)

use strict;
use Cwd;
use Win32API::File qw(:ALL);
use Win32::Sound;
use Time::HiRes qw(gettimeofday sleep);
use List::Util qw(max min);
use Getopt::Long;

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

warn "Ready. Waiting for your shake!\n";

sub get_pos {
    my $file = createFile("//./ShockMgr", "r ke") or die "Can't get ShockMgr device";
    DeviceIoControl($file, 0x733fc, [], 0, my($buf), 0x24, my($bytes), []);
    my @data = unpack "x4s*", $buf;
    return @data[1, 0];
}

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
    sleep 0.1;
}

my %par_tmp;

sub play_sound {
    my $volume = shift;
    my $num = int rand 5;
    my $filename = "hit$num.wav";
    $volume = int(65535 * min($volume / 15, 1));
    warn "playing $filename in $volume" if $debug;
    Win32::Sound::Volume($volume);
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

