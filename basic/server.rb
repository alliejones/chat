require 'socket'

# based on code from Working with TCP Sockets in Ruby

module Chat
  class Server
    CHUNK_SIZE = 1024 * 16
    attr_reader :handles

    class Connection
      CRLF = "\r\n"
      attr_reader :client, :server, :name

      def initialize(io, server)
        @client = io
        @request, @response = "", ""
        @name = 'anonymous'
        @server = server

        respond ">> Connected to server"

        on_writable
      end

      def on_data(data)
        if data.start_with?('NICK ')
          @name = data.chomp!.sub! 'NICK ', ''
          puts ">> Client ##{@client.fileno} is now known as #{@name}"
        else
          respond_to_peers "#{@name}: #{data.chomp!}"
        end
      end

      def respond_to_peers(data)
        @server.handles.each { |fileno, conn| conn.respond data unless fileno == @client.fileno }
      end

      def respond(data)
        @response << data + CRLF
        on_writable
      end

      def on_writable
        bytes = @client.write_nonblock(@response)
        @response.slice!(0, bytes)
      end

      def monitor_for_reading?
        true
      end

      def monitor_for_writing?
        !(@response.empty?)
      end
    end

    def initialize(port = 21)
      puts ">> Server listening on port #{port}"
      @control_socket = TCPServer.new(port)
      trap(:INT) { exit }
    end

    def run
      @handles = {}

      loop do
        to_read = @handles.values.select(&:monitor_for_reading?).map(&:client)
        to_write = @handles.values.select(&:monitor_for_writing?).map(&:client)

        readables, writables = IO.select(to_read + [@control_socket], to_write)

        readables.each do |socket|
          if socket == @control_socket
            io = @control_socket.accept
            connection = Connection.new(io, self)
            @handles[io.fileno] = connection
            puts ">> Client connected: ##{io.fileno} (total connections: #{@handles.length})"

          else
            connection = @handles[socket.fileno]

            begin
              data = socket.read_nonblock(CHUNK_SIZE)
              connection.on_data(data)
            rescue Errno::EAGAIN
            rescue EOFError
              @handles.delete(socket.fileno)
              puts ">> Client disconnected: ##{socket.fileno} (total connections: #{@handles.length})"
            end
          end
        end

        writables.each do |socket|
          connection = @handles[socket.fileno]
          connection.on_writable
        end
      end
    end
  end
end

server = Chat::Server.new(4444)
server.run