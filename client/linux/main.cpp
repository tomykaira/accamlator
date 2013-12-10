#include "mysql_image.hpp"
#include "capture.hpp"

int main(int argv, char** argc)
{
    std::string host = "localhost";
    std::string source = "test";
    if (argv == 3)
    {
        host = std::string(argc[1]);
        source = std::string(argc[2]);
    }
    MySQLImage my(host, source);
    Capture capture(my);

    capture.runPeriodicCapture();
    return 0;
}
