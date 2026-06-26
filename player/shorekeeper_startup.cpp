// shorekeeper_startup.cpp
// Plays a .wav at login with NO console/window.
//
// Behavior:
//   - If a path is passed as the first argument, it plays that file.
//   - Otherwise it plays "shorekeeper_hello.wav" located in the SAME
//     folder as this .exe (robust regardless of the working directory
//     the Startup folder / Task Scheduler launches it from).
//
// Notes:
//   - PlaySound handles uncompressed PCM .wav.
//   - SND_SYNC keeps the process alive until the clip finishes, then exits.
//
// Build (MinGW-w64):  g++ shorekeeper_startup.cpp -o shorekeeper_startup.exe -municode -lwinmm -mwindows -O2 -static
// Build (MSVC):       cl /O2 shorekeeper_startup.cpp /link winmm.lib

#include <windows.h>
#include <mmsystem.h>
#include <string>
#pragma comment(lib, "winmm.lib")   // MSVC: auto-link winmm (ignored by MinGW; use -lwinmm there)

// Returns the directory the running .exe lives in (with trailing backslash).
static std::wstring exeDir() {
    wchar_t buf[MAX_PATH];
    DWORD n = GetModuleFileNameW(NULL, buf, MAX_PATH);
    std::wstring path(buf, n);
    size_t slash = path.find_last_of(L"\\/");
    return (slash == std::wstring::npos) ? L"" : path.substr(0, slash + 1);
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, LPWSTR, int) {
    std::wstring target;

    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argv && argc >= 2 && argv[1][0] != L'\0') {
        target = argv[1];                       // explicit path argument
    } else {
        target = exeDir() + L"shorekeeper_hello.wav";  // default: next to the exe
    }
    if (argv) LocalFree(argv);

    PlaySoundW(target.c_str(), NULL, SND_FILENAME | SND_SYNC);
    return 0;
}
