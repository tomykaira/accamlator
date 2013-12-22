$LOAD_PATH.unshift(__dir__ + '/lib')
require 'images'
require 'base64'
require 'sinatra'
require 'ffi-rzmq'
require 'msgpack'

set :bind, '0.0.0.0'
set :port, 5000

def conn
  Mysql2::Client.new(host: 'localhost', username: 'accam_server', database: 'accamlator')
end

ctx = ZMQ::Context.new(1)
zmq_server = "tcp://0.0.0.0:#{ENV['ZMQ_PORT'] || 5995}"

get '/', provides: 'html' do
  sources = Images.new(conn).sources
  haml :index, locals: { sources: sources }
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

  zmq = ctx.socket(ZMQ::REQ)
  zmq.connect zmq_server
  zmq.send_string({ 'command' => 'update', 'target' => source }.to_msgpack)
  data = {}
  until data['command'] == 'image' || data['status'] == 'error'
    str = ''
    zmq.recv_string(str)
    data = MessagePack.unpack(str)
  end
  zmq.close

  if data['command'] == 'image' && data['result'] == 'succeeded'
    haml :show, locals: { captured_at: Time.now, encoded_image: Base64.encode64(data['png']) }
  else
    'Error: ' + data['message']
  end
end
