@echo off
echo Starting Mexican Train Server...
echo.
echo Server will start on default port 9957
echo Press Ctrl+C to stop the server
echo.
godot --headless scenes/server/headless_server.tscn
pause
