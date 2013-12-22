import zmq
import msgpack
import traceback
import subprocess
import os
from tempfile import mkstemp

def capture():
    fd, path = mkstemp(suffix=".png")
    try:
        os.close(fd)
        p = subprocess.Popen(["../linux/accam_client", path], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p.wait()
        if p.returncode != 0:
            (stdout, stderr) = p.communicate(None)
            return {'command': 'image', 'result': 'failed', 'message': stderr}
        else:
            with open(path, mode='rb') as f:
                return {'command': 'image', 'result': 'succeeded',  'png': f.read()}
    finally:
        os.remove(path)


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
            result = capture()
            client.send(result)
            print("Sent %s" % result['result'])
        if message.get(b'status') == b'error':
            print("Error response: %s" % resp)
        error_count = 0
    except:
        error_count += 1
        traceback.print_exc()
        if error_count >= 5:
            client.socket.close()
            exit(1)
