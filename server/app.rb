$LOAD_PATH.unshift(__dir__ + '/lib')
require 'images'
require 'base64'
require 'sinatra'

CONN = Mysql2::Client.new(host: 'localhost', username: 'accam_server', database: 'accamlator')

get '/', provides: 'html' do
  sources = Images.new(CONN).sources
  haml :index, locals: { sources: sources }
end

get '/:source' do
  source = params[:source]
  image = Images.new(CONN).latest_image(source)
  haml :show, locals: { captured_at: image['captured_at'], encoded_image: Base64.encode64(image['data']) }
end
