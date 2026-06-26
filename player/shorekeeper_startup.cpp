#include <windows.h>
#include <mmsystem.h>
#include <string>
#pragma comment(lib, "winmm.lib")

static std::wstring exeDir() {
    wchar_t buf[MAX_PATH];
    DWORD n = GetModuleFileNameW(NULL, buf, MAX_PATH);
    std::wstring path(buf, n);
    size_t slash = path.find_last_of(L"\\/");
    return (slash == std::wstring::npos) ? L"" : path.substr(0, slash + 1);
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, LPWSTR lpCmdLine, int) {
    std::wstring target;

    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argv && argc >= 2 && argv[1][0] != L'\0') {
        target = argv[1];
    }
    else {
        target = exeDir() + L"shorekeeper_hello.wav";
    }
    if (argv) LocalFree(argv);

    PlaySoundW(target.c_str(), NULL, SND_FILENAME | SND_SYNC);
    return 0;
}
