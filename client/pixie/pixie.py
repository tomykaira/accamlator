import zmq
import umsgpack

context = zmq.Context()

socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5995")

socket.send(umsgpack.packb({'command': 'register', 'name': 'test'}))
message = socket.recv()
print("Received reply [ %s ]" % (umsgpack.unpackb(message)))
