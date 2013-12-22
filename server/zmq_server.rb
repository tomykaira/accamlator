require 'ffi-rzmq'
require 'msgpack'

def assert(rc)
  raise "Last API call failed at #{caller(1)}" unless rc >= 0
end

ctx = ZMQ::Context.new(1)

server = ctx.socket(ZMQ::XREP)
server.bind "tcp://0.0.0.0:#{ENV['ZMQ_PORT'] || 5995}"

class << server
  def respond(client, message)
    assert(send_string(client, ZMQ::SNDMORE))
    assert(send_string('', ZMQ::SNDMORE))
    assert(send_string(message.to_msgpack))
  end
end

END {
  server.close
  ctx.terminate
}

update_waiters = []

class ClientManager
  def initialize
    @clients = {}
  end

  def register(name, info)
    @clients[name] = info
  end

  def by_info(info)
    @clients.select { |k, v| v == info }.keys.first
  end

  def by_name(name)
    @clients[name]
  end
end

clients = ClientManager.new

class UpdateWaiter
  attr_reader :info, :target

  def initialize(info, target)
    @info, @target = info, target
  end
end

def save_image(name, png)
  now = Time.now
  dir = File.join(__dir__, 'stored', name, now.strftime('%Y-%m-%d'))
  FileUtils.mkdir_p(dir)
  File.write(File.join(dir, now.strftime('%H_%M.png')), png, nil, mode: 'wb')
end

loop do
  begin
    routing_info = ''
    assert(server.recv_string(routing_info))
    received_msg = ''
    while server.more_parts?
      assert(server.recv_string(received_msg))
    end

    data = MessagePack.unpack(received_msg)
    case data['command']
    when 'register'
      puts "#{data['name']} is registered"
      clients.register(data['name'], routing_info)
      server.respond(routing_info, { 'status' => 'ack' })
    when 'update'
      target = data['target']
      info = clients.by_name(target)
      if info
        update_waiters << UpdateWaiter.new(routing_info, target)
        server.respond(info, { 'command' => 'update' })
      else
        server.respond(routing_info, { 'status' => 'error', 'message' => 'unknown client' })
      end
    when 'image'
      name = clients.by_info(routing_info)
      found, new_waiters = update_waiters.partition { |w| w.target == name }
      found.each do |waiter|
        server.respond(waiter.info, data)
      end
      save_image(name, data['png']) if data['result'] == 'succeeded'
      update_waiters = new_waiters
      server.respond(routing_info, { 'status' => 'ack' })
    end
  rescue
    $stderr.puts($!)
    $stderr.puts($@)
  end
end
