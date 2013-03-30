@ECHO OFF
REM Papilio-Arcade.bat %emupath% %maincpu_value% %maincpu_entity_value% %maincpu_map_value% %maincpu_addrbits_value% %hardware% STEP iniFilename(optional)

CD %1\PapilioTMP\

REM Detect Papilio Board

IF NOT EXIST %1\PapilioTMP\papilio-detect.txt ( 
IF NOT EXIST %1\PapilioTMP\devlist.txt ( 
copy %1\devlist.txt %1\PapilioTMP\devlist.txt  > NUL
)
%1\papilio-prog.exe -j > papilio-detect.txt
)
set /p PapilioVersion= < papilio-detect.txt

IF "%PapilioVersion%" == "JTAG chainpos: 0 Device IDCODE = 0x41c22093	Desc: XC3S500E" GOTO Papilio500Detected
IF "%PapilioVersion%" == "JTAG chainpos: 0 Device IDCODE = 0x24001093	Desc: XC6SLX9" GOTO PapilioProDetected
GOTO PapilioNotDetected

:PapilioNotDetected
ECHO(
ECHO Could NOT detect Papilio Type!
ECHO(
PAUSE
GOTO Done

:PapilioProDetected
ECHO(
ECHO Papilio Pro Detected (Unsupported at this time.. Bother Jack)
ECHO(
PAUSE
GOTO Done

:Papilio500Detected
SET PapilioHW=hardware_p1_500K
GOTO NextStep

:NextStep

REM Sleep (Let winders catch up for write caching etc.. 500ms delay Thanks Rob van der Woude)
> Sleep.vbs ECHO Wscript.Sleep 500
CSCRIPT //NoLogo Sleep.vbs

REM ECHO Generating %3 from %emupath%\PapilioTMP\%2
ECHO Generating %3.bin
ECHO(
COPY /B %2 %3.bin  > NUL

ECHO Running ROMGen on %3.bin
IF "%8"=="" GOTO ROMGenNoINI
IF "%8"=="%%rom0_decrypt_ini_value%%" GOTO ROMGenNoINI
GOTO ROMGenINI

:ROMGenNoINI
%1\romgen.exe %1\PapilioTMP\%3.bin %3 %5 m > %1\PapilioTMP\%3.mem
GOTO ROMGenFinished

:ROMGenINI
ECHO Encrypted ROM. Decrypting using: %1\patches\%8
%1\romgen.exe %1\PapilioTMP\%3.bin %3 %5 m -ini:%1\patches\%8 > %1\PapilioTMP\%3.mem
GOTO ROMGenFinished


:ROMGenFinished
REM Sleep again.. (500ms)
CSCRIPT //NoLogo Sleep.vbs

IF "%7"=="1" GOTO Step1
goto Step2Plus

:Step1
ECHO Injecting %3.mem into base bitfile
%1\data2mem.exe -bm %1\hardware\%6_%PapilioHW%_bd.bmm -bt %1\hardware\%6_%PapilioHW%.bit -bd %1\PapilioTMP\%3.mem tag avrmap.%4 -o b %1\PapilioTMP\final.bit  > NUL

goto Done

:Step2Plus
move /Y final.bit in.bit > NUL
%1\data2mem.exe -bm %1\hardware\%6_%PapilioHW%_bd.bmm -bt %1\PapilioTMP\in.bit -bd %1\PapilioTMP\%3.mem tag avrmap.%4 -o b %1\PapilioTMP\final.bit  
goto Done

:Done
REM Sleep again.. (500ms)
CSCRIPT //NoLogo Sleep.vbs
