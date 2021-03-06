require 'rubygems'
require 'em-websocket'
require 'json'
require 'pry'

module WSChat
  class Message
    attr_accessor :content, :type, :client

    def initialize(content=nil, type='user:message', client=nil)
      @content = content
      @type = type
      @client = client
    end

    def self.from_json(json_string)
      msg = self.new
      data = JSON.parse json_string
      msg.content = data['content']
      msg.type = data['type']
      msg
    end

    def to_json(*a)
      as_json.to_json(*a)
    end

    def as_json(options = {})
      user = @client ? { id: @client.sid, username: @client.username } : nil
      { type: @type, content: @content, user: user }
    end
  end

  class Client
    attr_accessor :sid, :ws, :server, :username

    def initialize(ws)
      @ws = ws
      @sid = nil
      @server = nil
      @username = 'Anonymous'
    end

    def create_msg(content=nil, type='user')
      WSChat::Message.new(content, type, self)
    end

    def create_msg_from_json(json_string)
      msg = WSChat::Message.from_json(json_string)
      msg.client = self
      msg
    end

    def login(username)
      @username = username
      @server.broadcast self.create_msg(nil, 'user:login')
    end

    def logout
      @server.broadcast self.create_msg(nil, 'user:logout')
    end

    def handle(message)
      case message.type
      when 'server:login'
        self.login message.content
      else
        server.broadcast message
      end
    end

    def send(message)
      @ws.send message.to_json
    end

    def to_json(*a)
      as_json.to_json(*a)
    end

    def as_json(options = {})
      { id: @sid, username: @username }
    end
  end

  class Server
    def initialize(channel)
      @channel = channel
      @clients = []
    end

    def broadcast(message)
      @channel.push message.to_json
    end

    def subscribe(client)
      sid = @channel.subscribe { |msg| client.ws.send msg }
      client.sid = sid
      client.server = self
      @clients.push client
      puts "Client ##{client.sid} connected, #{@clients.length} connections"

      client.send WSChat::Message.new(@clients.select{ |c| c.sid != sid }, 'server:connection')
    end

    def unsubscribe(client)
      @clients.delete(client)
      client.logout
      puts "Client ##{client.sid} disconnected, #{@clients.length} connections"
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

      ws.onmessage do |msg|
        puts "Client ##{client.sid}: #{msg}"
        message = client.create_msg_from_json(msg)
        client.handle message
      end
    }
  end

  puts "Server listening on 0.0.0.0:8080"
}