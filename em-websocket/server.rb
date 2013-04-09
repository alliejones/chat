require 'rubygems'
require 'em-websocket'
require 'json'

module WSChat
  class Client
    attr_accessor :sid, :ws

    def initialize(ws)
      @ws = ws
      @sid = nil
    end

    def login(username)
      @username = username
    end
  end

  class Server
    def initialize(channel)
      @channel = channel
      @clients = {}
    end

    def broadcast(msg)
      @channel.push msg
    end

    def subscribe(client)
      sid = @channel.subscribe { |msg| client.ws.send msg }
      client.sid = sid
      @clients[sid] = client
      message = "Client ##{client.sid} connected, #{@clients.length} connections"
      puts message
      self.broadcast message
    end

    def unsubscribe(client)
      @clients.delete(client.sid)
      message = "Client ##{client.sid} disconnected, #{@clients.length} connections"
      self.broadcast message
    end

    def handle(client, msg)
      self.broadcast msg
    end
  end
end

EM.run {
  @server = WSChat::Server.new(EM::Channel.new)

  EM::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
    ws.onopen {
      client = WSChat::Client.new(ws)
      @server.subscribe client

      ws.onclose { @server.unsubscribe client }

      ws.onmessage { |msg| @server.handle client, msg }
    }
  end

  puts "Server listening on 0.0.0.0:8080"
}