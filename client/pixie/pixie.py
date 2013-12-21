import zmq
import msgpack
import traceback

context = zmq.Context()

class Client:
    def __init__(self, context, uri):
        self.socket = context.socket(zmq.XREQ)
        self.socket.connect(uri)

    def read(self):
        sender = self.socket.recv()
        return msgpack.unpackb(self.socket.recv())

    def send(self, data):
        self.socket.send(msgpack.packb(data))

client = Client(context, "tcp://localhost:5995")

client.send({'command': 'register', 'name': 'test'})
print("Received reply [ %s ]" % (client.read()))

error_count = 0
while True:
    try:
        message = client.read()
        if message.get(b'command') == b'update':
            with open("/tmp/test.png", mode='rb') as f:
                client.send({'command': 'image', 'png': f.read()})
        if message.get(b'status') == b'error':
            print("Error response: %s" % resp)
        error_count = 0
    except:
        error_count += 1
        traceback.print_exc()
        if error_count >= 5:
            client.socket.close()
            exit(1)
