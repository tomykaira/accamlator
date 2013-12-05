$LOAD_PATH.unshift(__dir__ + '/lib')
require 'images'
require 'fileutils'
require 'time'

CONN = Mysql2::Client.new(host: 'localhost', username: 'accam_server', database: 'accamlator')
images = Images.new(CONN)

loop do
  images.sources.each do |source|
    begin
      latest = images.latest_image(source)
      next unless latest
      time = latest['captured_at']
      dir = File.join(__dir__, 'stored', source, time.strftime('%Y-%m-%d'))
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, time.strftime('%H_%M.png')), latest['data'], nil, mode: 'wb')
      images.delete_before(source, latest['id'])
    rescue
      $stderr.puts($!)
      $stderr.puts($@)
    end
  end
  sleep 60
end
