#include "opencv2/opencv.hpp"
#include <vector>
#include <boost/filesystem/fstream.hpp>
#include "mysql_image.hpp"

int main(int, char**)
{
    cv::VideoCapture cap(0); // open the default camera
    if(!cap.isOpened()) {  // check if we succeeded
        std::cerr << "Failed to open camera" << std::endl;
        return -1;
    }

    MySQLImage my("localhost", "test");

    cv::Mat edges;
    cv::namedWindow("edges",1);

    cv::Mat frame;
    std::vector<uchar> buf;
    cap >> frame; // get a new frame from camera
    cv::imencode(".png", frame, buf);
    std::string data(buf.begin(), buf.end());
    my.saveImage(data);

    // the camera will be deinitialized automatically in VideoCapture destructor
    return 0;
}
