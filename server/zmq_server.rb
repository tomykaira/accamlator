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

loop do
  begin
    routing_info = ''
    assert(server.recv_string(routing_info))
    received_msg = ''
    while server.more_parts?
      assert(server.recv_string(received_msg))
    end

    data = MessagePack.unpack(received_msg)
    response =
      case data['command']
      when 'register'
        puts "#{data['name']} is registered"
        clients.register([data['name']], routing_info)
        { 'command' => 'ack' }
      when 'update'
        update_waiters << UpdateWaiter.new
      when 'image'
        name = clients.by_info(routing_info)
        now = Time.now
        found, new_waiters = update_waiters.partition { |w| w.target == name }
        found.each do |waiter|
          server.respond(waiter.info, data)
        end
        dir = File.join(__dir__, 'stored', name, now.strftime('%Y-%m-%d'))
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, time.strftime('%H_%M.png')), data['png'], nil, mode: 'wb')
        update_waiters = new_waiters
        { 'command' => 'ack' }
      end
    server.respond(routing_info, response)
  rescue
    $stderr.puts($!)
    $stderr.puts($@)
  end
end
