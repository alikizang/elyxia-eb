@echo off
echo ========================================================
echo   Compilation d'Elyxia EB pour Windows (.exe)
echo ========================================================
echo.

call flutter pub get
call flutter build windows --release

echo.
echo ========================================================
echo   Compilation terminee !
echo   Executables situes dans : build\windows\x64\runner\Release\
echo ========================================================
pause
