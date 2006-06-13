all: exe zip
exe: thinkpad-saber.exe
zip: thinkpad-saber.zip

thinkpad-saber.exe: thinkpad-saber.pl
	pp -o thinkpad-saber.exe thinkpad-saber.pl

thinkpad-saber.zip:
	zip -r thinkpad-saber . -i \*.exe \*.wav
