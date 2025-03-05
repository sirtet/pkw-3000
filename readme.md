Me poking around the AVAL PKW-3000 EP-ROM Programmer, aiming at writing a Hellorld! Program for it.

Work based on Edgar's reverse engineered Disassembly and Schematics found on the [PKW-3000 EP-ROM Programmer resources page](http://matthieu.benoit.free.fr/PKW-3000_E-PROM_programmer_resources.htm)


## Files
[PKW-3000_User_Manual_with_notes_OCR.pdf](https://github.com/sirtet/pkw-3000/blob/main/PKW-3000_User_Manual_with_notes_OCR.pdf "PKW-3000_User_Manual_with_notes_OCR.pdf")
OCR Scanned User Manual with annotations (corrections, notes).

[PKW.ASM](https://github.com/sirtet/pkw-3000/blob/main/PKW.ASM "PKW.ASM")
Original Disassembly by Edgar.

[pkw2.asm](https://github.com/sirtet/pkw-3000/blob/main/pkw2.asm "pkw2.asm")
My first edit with few changes. Still with ISIS-II compatible syntax.

[pkw2_8085.asm](https://github.com/sirtet/pkw-3000/blob/main/pkw2_8085.asm "pkw2_8085.asm")
Most additional work is in here, changed to [8085-Simulator](https://github.com/ForNextSoftwareDevelopment/8085) compatible Syntax.

[hellorld.asm](https://github.com/sirtet/pkw-3000/blob/main/hellorld.asm "hellorld.asm")
As the name implies...

[uploader.txt](https://github.com/sirtet/pkw-3000/blob/main/uploader.txt "uploader.txt")
A script file for PuTTY, used to send the hellorld binary to the Programmer

## HELLOrld
How to use:
1. Use 8085 Simulator to save binary from hellorld.asm
2. Use a HEX editor to copy binary data in HEX-form
3. Paste it into uploader.txt
4. Use PuTTY/KiTTY's *Send script file* option with uploader.txt
  or, use a paper tape to send the data in real style ;-)

Result of the first running version (HELLorLd finalally became HELLOrld)
![hellorld-on-PKW-3000](https://raw.githubusercontent.com/sirtet/pkw-3000/refs/heads/main/hellorld-on-PKW-3000.jpg)
