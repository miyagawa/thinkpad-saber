all: thinkpad-saber.exe

thinkpad-saber.exe: thinkpad-saber.pl
	pp -o thinkpad-saber.exe thinkpad-saber.pl
