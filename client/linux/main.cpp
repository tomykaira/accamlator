#include "mysql_image.hpp"
#include "capture.hpp"

int main(int argv, char** argc)
{
    std::string host = "localhost";
    std::string source = "test";
    bool flip = false;
    if (argv >= 3)
    {
        host = std::string(argc[1]);
        source = std::string(argc[2]);
    }
    if (argv >= 4)
    {
        auto arg = std::string(argc[3]);
        flip = arg == "1" || arg == "true" || arg == "flip";
    }
    MySQLImage my(host, source);
    Capture capture(my, flip);

    capture.runPeriodicCapture();
    return 0;
}
