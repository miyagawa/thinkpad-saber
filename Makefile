all: exe zip
exe: thinkpad-saber.exe
zip: thinkpad-saber.zip

thinkpad-saber.exe: thinkpad-saber.pl
	pp --icon "resources\tpsaber.ico" --gui -o thinkpad-saber.exe -a resources\tpsaber.ico thinkpad-saber.pl

thinkpad-saber.zip:
	zip -r thinkpad-saber . -i \*.exe \*.wav
