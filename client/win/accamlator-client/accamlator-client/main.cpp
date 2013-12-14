#define _WIN32_WINNT 0x501
#include "capture.hpp"

int main(int argv, char** argc)
{
    std::string host = "localhost";
    std::string source = "test";
	bool flip;
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
	try {
		MySQLImage my(host, source);
		Capture capture(my, flip);
		capture.runPeriodicCapture();
	} catch (std::string e) {
		std::cerr << "Failed to connect to MySQL: " << e << std::endl;
		return 1;
	}

    // the camera will be deinitialized automatically in VideoCapture destructor
    return 0;
}
