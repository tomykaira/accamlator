all: accam_client
CXXFLAGS=-std=c++11 -Wall -g -O2
LDFLAGS=-lopencv_core -lopencv_video -lopencv_highgui -lopencv_imgproc -lboost_system -lboost_filesystem

accam_client: main.o mysql_image.cpp mysql_image.hpp
	g++ -o $@ $^ $(LDFLAGS)
