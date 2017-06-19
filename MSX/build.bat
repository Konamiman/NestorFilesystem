@echo off

echo --- Building...
call compile.bat
if errorlevel 1 goto :end

echo --- Mounting disk image file...
call mount.bat
if errorlevel 1 goto :end

echo --- Copying file...
copy NFS.COM Y:

echo --- Unmounting disk image file...
ping 1.1.1.1 -n 1 -w 1500 >NUL
call unmount.bat

:end
