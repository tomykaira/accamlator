all: accam_client
CXXFLAGS=-std=c++11 -Wall -g -O2
LDFLAGS=-lopencv_core -lopencv_video -lopencv_highgui -lopencv_imgproc -lboost_system -lmysqlclient

accam_client: main.o mysql_image.o mysql_image.hpp capture.o capture.hpp
	g++ $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
