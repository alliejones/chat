require 'rubygems'
require 'em-websocket'
require 'json'
require 'pry'

module WSChat
  class Message
    attr_accessor :content, :type, :client

    def initialize(content=nil, type='user', client=nil)
      @content = content
      @type = type
      @client = client
    end

    def from_json!(json_string)
      data = JSON.parse json_string
      @content = data['content']
      @type = data['type']
      self
    end

    def to_json
      if @type == 'user'
        { type: @type, content: @content, user: @client.username }.to_json
      else
        { type: @type, content: @content, user: nil }.to_json
      end
    end
  end

  class Client
    attr_accessor :sid, :ws, :server, :username

    def initialize(ws)
      @ws = ws
      @sid = nil
      @server = nil
      @username = 'test'
    end

    def create_msg(content=nil)
      WSChat::Message.new(content, 'user', self)
    end

    def login(username)
      @username = username
    end

    def handle(message)
      case message.type
      when 'login'
        self.login message.content
      else
        server.broadcast message
      end
    end

    def parse_command(content)
      content.split
    end
  end

  class Server
    def initialize(channel)
      @channel = channel
      @clients = {}
    end

    def broadcast(message)
      @channel.push message.to_json
    end

    def subscribe(client)
      sid = @channel.subscribe { |msg| client.ws.send msg }
      client.sid = sid
      client.server = self
      @clients[sid] = client

      message = "Client ##{client.sid} connected, #{@clients.length} connections"
      puts message
      self.broadcast WSChat::Message.new(message, 'server')
    end

    def unsubscribe(client)
      @clients.delete(client.sid)
      message = "Client ##{client.sid} disconnected, #{@clients.length} connections"
      self.broadcast WSChat::Message.new(message, 'server')
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
        message = client.create_msg.from_json!(msg)
        client.handle message
      end
    }
  end

  puts "Server listening on 0.0.0.0:8080"
}