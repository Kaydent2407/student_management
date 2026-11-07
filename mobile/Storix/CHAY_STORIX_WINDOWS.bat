@echo off
chcp 65001 >nul
cd /d "%~dp0"
where node >nul 2>&1
if errorlevel 1 (
  echo Ban can cai Node.js 22.13+ truoc khi chay Storix.
  pause
  exit /b 1
)
if not exist node_modules (
  echo Dang cai cac thu vien lan dau...
  call npm install
  if errorlevel 1 (
    echo Khong the cai thu vien. Kiem tra ket noi Internet va thu lai.
    pause
    exit /b 1
  )
)
echo Khoi dong Storix. Nhan W de mo tren web hoac quet QR bang Expo Go Android.
call npx expo start
pause
