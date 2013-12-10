#include "capture.hpp"

Capture::Capture(MySQLImage &my) :
  cap_(0), my_(my), io_(), timer_(io_, boost::posix_time::milliseconds(interval_))
{
  if (!cap_.isOpened()) {
    throw "Failed to open device";
  }
  timer_.async_wait(boost::bind(&Capture::savePeriodically, this));
}

void Capture::runPeriodicCapture()
{
  while (true) {
    cap_.grab();
    io_.poll();
  }
}

void Capture::savePeriodically()
{
  cv::Mat frame;
  cap_.retrieve(frame);

  if (frame.empty()) {
    std::cerr << "Frame is empty" << std::endl;
  } else {
    std::vector<uchar> buf;
    cv::imencode(".png", frame, buf);
    std::string data(buf.begin(), buf.end());
    my_.saveImage(data);
  }

  resetTimer();
  return;
}

void Capture::resetTimer()
{
  timer_.expires_at(timer_.expires_at() + boost::posix_time::milliseconds(interval_));
  timer_.async_wait(boost::bind(&Capture::savePeriodically, this));
}
