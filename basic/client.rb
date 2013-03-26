require 'socket'

module Chat
  class EventedClient
    CHUNK_SIZE = 1024 * 16
    CRLF = "\r\n"

    def initialize(host, socket)
      @socket = Socket.new(:INET, :STREAM)
      @remote_addr = Socket.pack_sockaddr_in(socket, host)
      @user_input = ''
      @server_data = ''
      trap(:INT) { exit }
    end

    def run
      @socket.connect(@remote_addr)

      puts 'What is your name?'
      name = gets
      set_nickname name

      loop do
        begin
          server_data = @socket.read_nonblock(CHUNK_SIZE)
          on_data(server_data)
        rescue Errno::EAGAIN
        rescue EOFError
          exit
        end

        begin
          input = STDIN.read_nonblock(CHUNK_SIZE)
          on_input(input)
        rescue Errno::EAGAIN
        rescue EOFError
        end
      end
    end

    def on_input(input)
      @user_input << input

      if @user_input.end_with?("\n")
        @user_input.chomp! << CRLF
        on_writable
      end
    end

    def on_writable
      bytes = @socket.write_nonblock(@user_input)
      @user_input.slice!(0, bytes)
    end

    def on_data(input)
      @server_data << input

      if @server_data.end_with?(CRLF)
        puts @server_data
        @server_data = ''
      end
    end

    def set_nickname(name)
      @socket.write("NICK #{name}")
    end
  end
end

client = Chat::EventedClient.new('localhost', 4444)
client.run
