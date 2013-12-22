all: accam_client
CXXFLAGS=-std=c++11 -Wall -g -O2

accam_client: main.o
	g++ $(CXXFLAGS) -o $@ $^ `pkg-config --libs opencv`
