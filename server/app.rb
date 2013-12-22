$LOAD_PATH.unshift(__dir__ + '/lib')
require 'base64'
require 'sinatra'
require 'ffi-rzmq'
require 'msgpack'

set :bind, '0.0.0.0'
set :port, 5000

CTX = ZMQ::Context.new(1)
ZMQ_SERVER = "tcp://0.0.0.0:#{ENV['ZMQ_PORT'] || 5995}"

def communicate(message)
  zmq = CTX.socket(ZMQ::REQ)
  zmq.connect ZMQ_SERVER
  zmq.send_string(message.to_msgpack)
  str = ''
  zmq.recv_string(str)
  data = MessagePack.unpack(str)
  zmq.close
  data
end

get '/', provides: 'html' do
  data = communicate('command' => 'list-clients')
  haml :index, locals: { sources: data['clients'] }
end

get '/stored*' do |c|
  file = File.join(__dir__, 'stored', *(c.split('/').delete_if(&:empty?)))
  if File.file?(file)
    content_type = file.end_with?('.png') ? 'image/png' : 'text/plain'
    [200, { 'Content-Type' => content_type }, File.read(file, mode: 'rb')]
  else
    files = Dir[file + '/*'].map { |path| path.gsub(__dir__, '') }.sort
    haml :file_index, locals: { files: files }
  end

end

get '/:source' do
  source = params[:source]
  data = communicate({ 'command' => 'update', 'target' => source })

  if data['command'] == 'image' && data['result'] == 'succeeded'
    haml :show, locals: { captured_at: Time.now, encoded_image: Base64.encode64(data['png']) }
  else
    'Error: ' + data['message']
  end
end
