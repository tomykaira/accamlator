#include "opencv2/opencv.hpp"
#include <vector>
#include <boost/asio.hpp>
#include <boost/timer.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include "mysql_image.hpp"

int main(int argv, char** argc)
{
    std::string host = "localhost";
    std::string source = "test";
    if (argv == 3)
    {
        host = std::string(argc[1]);
        source = std::string(argc[2]);
    }
	try {
		MySQLImage my(host, source);

    boost::asio::io_service io;

    while(1) {
        boost::timer te;

        cv::VideoCapture cap(0); // open the default camera
        if(!cap.isOpened()) {  // check if we succeeded
            std::cerr << "Failed to open camera" << std::endl;
            return -1;
        }
        cv::Mat frame;
        std::vector<uchar> buf;
        cap >> frame; // get a new frame from camera
        cv::imencode(".png", frame, buf);
        std::string data(buf.begin(), buf.end());
        my.saveImage(data);
        cap.release();

        boost::asio::deadline_timer t(io, boost::posix_time::milliseconds(1000.0 - te.elapsed() * 1000));
        t.wait();
    }
	} catch (std::string e) {
		std::cerr << "Failed to connect to MySQL: " << e << std::endl;
		return 1;
	}

    // the camera will be deinitialized automatically in VideoCapture destructor
    return 0;
}
