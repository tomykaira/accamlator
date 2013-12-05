$LOAD_PATH.unshift(__dir__ + '/lib')
require 'images'
require 'base64'
require 'sinatra'

set :bind, '0.0.0.0'
set :port, 5000

CONN = Mysql2::Client.new(host: 'localhost', username: 'accam_server', database: 'accamlator')

get '/', provides: 'html' do
  sources = Images.new(CONN).sources
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
  image = Images.new(CONN).latest_image(source)
  haml :show, locals: { captured_at: image['captured_at'], encoded_image: Base64.encode64(image['data']) }
end
