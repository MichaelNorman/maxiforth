@echo off
cd /d "%~dp0"
cmake -S windows -B build-winsrc && cmake --build build-winsrc
ndisasm -b 64 .\build-winsrc\winstubs.bin -p intel > .\windows\winstubs.txt
copy .\build-winsrc\winstubs.bin .\windows\winstubs.bin