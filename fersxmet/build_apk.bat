@echo off
echo ========================================
echo   FERSXMET - Compilando APK Release
echo ========================================
echo.
echo Iniciando compilacion...
echo Esto puede tardar varios minutos.
echo.

flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   APK COMPILADO EXITOSAMENTE
    echo ========================================
    echo.
    echo Ubicacion: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Para instalar en tu dispositivo:
    echo 1. Conecta tu dispositivo por USB
    echo 2. Ejecuta: adb install -r build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo O copia el APK a tu dispositivo e instalalo manualmente.
    echo.
) else (
    echo.
    echo ========================================
    echo   ERROR EN LA COMPILACION
    echo ========================================
    echo.
    echo Revisa los errores arriba.
    echo.
)

pause
