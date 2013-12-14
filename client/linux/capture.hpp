#ifndef _CAPTURE_H_
#define _CAPTURE_H_

#include <opencv2/opencv.hpp>
#include <vector>
#include <boost/bind.hpp>
#include <boost/asio.hpp>
#include <boost/timer.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include "mysql_image.hpp"

class Capture
{
private:
  static const int interval_ = 1000;
  cv::VideoCapture cap_;
  const MySQLImage my_;
  const bool flip_;
  boost::asio::io_service io_;
  boost::asio::deadline_timer timer_;

  void savePeriodically();
  void resetTimer();

public:
  Capture(MySQLImage &my, bool flip);

  void runPeriodicCapture();
};

#endif /* _CAPTURE_H_ */
