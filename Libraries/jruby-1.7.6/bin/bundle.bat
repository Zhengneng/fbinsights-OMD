@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
@"jruby.exe" "c:/Users/Nathan.Qiu/Documents/AptanaStudio3Workspace/fbinsights/Libraries/jruby-1.7.6/bin/bundle" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
@"jruby.exe" "%~dpn0" %*
