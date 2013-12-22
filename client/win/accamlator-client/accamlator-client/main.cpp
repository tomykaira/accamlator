#define _WIN32_WINNT 0x501
#include <iostream>

#include <opencv2/opencv.hpp>

int main(int argv, char** argc)
{
    cv::VideoCapture cap(0);
    if (!cap.isOpened()) {
        std::cerr << "Failed to open device" << std::endl;
        return 1;
    }
    cv::Mat frame;
    cap >> frame;
    if (frame.empty()) {
        std::cerr << "Frame is empty" << std::endl;
        return 1;
    }
    cv::imwrite(argc[1], frame);
    return 0;
}
