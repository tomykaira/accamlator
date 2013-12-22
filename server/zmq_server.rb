require 'ffi-rzmq'
require 'msgpack'
require 'benchmark'

def assert(rc)
  raise "Last API call failed at #{caller(1)}" unless rc >= 0
end

class Client
  TIMEOUT = 5 # seconds
  attr_accessor :name, :info

  def initialize(name, info)
    self.name = name
    self.info = info
    @sent_at = nil
    @requesting = false
    @listeners = []
  end

  def add_listener(info)
    @listeners << info
  end

  def clear_listeners
    l = @listeners
    @listeners = []
    l
  end

  def request(server, message)
    server.respond(info, message)
    @sent_at = Time.now
    @requesting = true
  end

  def request_update(server)
    request(server, { 'command' => 'update' })
  end

  def responded
    @requesting = false
  end

  def alive?
    !@requesting || @sent_at >= Time.now - TIMEOUT
  end
end

class ClientManager
  include Enumerable

  def initialize
    @clients = []
  end

  def register(name, info)
    @clients << Client.new(name, info)
  end

  def by_info(info)
    @clients.find { |c| c.info == info }
  end

  def by_name(name)
    @clients.find { |c| c.name == name }
  end

  def names
    @clients.map(&:name)
  end

  def each(&block)
    @clients.each(&block)
  end

  def responded(new_info)
    if client = by_info(new_info)
      client.responded
    end
  end

  def update_liveness(server)
    @clients.delete_if do |c|
      unless c.alive?
        puts "#{c.name} went away"
        c.clear_listeners.each do |listener|
          server.respond(listener, { 'status' => 'error', 'message' => 'client disconnected' })
        end
        true
      end
    end
  end
end

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

def process_message(server, clients, routing_info, data)
  case data['command']
  when 'register'
    puts "#{data['name']} is registered"
    clients.register(data['name'], routing_info)
    server.respond(routing_info, { 'status' => 'ack' })
  when 'list-clients'
    server.respond(routing_info, { 'status' => 'ack', 'clients' => clients.names })
  when 'update'
    target = data['target']
    client = clients.by_name(target)
    if client
      client.add_listener(routing_info)
      client.request_update(server)
    else
      server.respond(routing_info, { 'status' => 'error', 'message' => 'unknown client' })
    end
  when 'image'
    client = clients.by_info(routing_info)
    client.clear_listeners.each do |waiter|
      server.respond(waiter, data)
    end
    save_image(client.name, data['png']) if data['result'] == 'succeeded'
    server.respond(routing_info, { 'status' => 'ack' })
  end
end

ctx = ZMQ::Context.new(1)

server = ctx.socket(ZMQ::XREP)
server.bind "tcp://0.0.0.0:#{ENV['ZMQ_PORT'] || 5995}"

poller = ZMQ::Poller.new
poller.register_readable(server)

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

clients = ClientManager.new
prev_update = Time.now

loop do
  begin
    assert(poller.poll(1000))

    if readable = poller.readables.first
      routing_info = ''
      assert(readable.recv_string(routing_info))
      received_msg = ''
      while server.more_parts?
        assert(readable.recv_string(received_msg))
      end
      process_message(server, clients, routing_info, MessagePack.unpack(received_msg))
      clients.responded(routing_info)
    end

    now = Time.now
    if now.min != prev_update.min
      puts "Updating all clients"
      clients.each { |c| c.request_update(server) }
      prev_update = now
    end

    clients.update_liveness(server)
  rescue
    $stderr.puts($!)
    $stderr.puts($@)
  end
end

timer.kill
timer.join
