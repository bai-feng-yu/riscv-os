#include "userlib.h"

int main(int argc, char* argv[])
{
    char tmp[128];
    while(1) {
        memset(tmp, 0, 128);
        stdout("test> ", 6);
        int n = (int)stdin(tmp, 127);
        if(n <= 0)
            return 0;
        tmp[127] = 0;
        // 直接按回车（或 CRLF）也退出
        if((n == 1 && tmp[0] == '\n') || (n == 1 && tmp[0] == '\r') ||
           (n == 2 && tmp[0] == '\r' && tmp[1] == '\n'))
            return 0;
        if(strncmp(tmp, "exit", 4) == 0)
            return 0;
        stdout(tmp, (uint32)n);
    }
}