module Sudokl

  module Client

    def self.start(opts = {})
      client = Base.new(opts)
      client.connect!
      client
    end

    class Base
      attr_reader :host, :port, :timeout, :sock, :name

      def initialize(options = {})
        @name     = options[:name]  || "Client"
        @host     = options[:host]  || "127.0.0.1"
        @port     = (options[:port] || 44444).to_i
        @timeout  = (options[:timeout] || 5).to_i
        @sock     = nil
      end

      def connect!
        with_timeout(@timeout) do
          @sock = TCPSocket.new(host, port)
        end
      end

      def disconnect
        # untested
        return unless connected?

        begin
          @sock.close
        rescue
        ensure
          @sock = nil
        end
      end

      def reconnect
        disconnect
        connect
      end

      def connected?
        !! @sock
      end

      def call(command)
        process(command)
      end

      def read
        begin
          response = @sock.recvfrom( 1024 )[0].chomp
        rescue Errno::EAGAIN
          disconnect
          raise Errno::EAGAIN, "Timeout reading from the socket"
        end
        raise Errno::ECONNRESET, "Connection lost" unless response

        response
      end

      def process(command)
        ensure_connected do
          @sock.puts(command)
          @sock.flush
          yield if block_given?
        end
      end

      begin
        require "system_timer"

        def with_timeout(seconds, &block)
          SystemTimer.timeout_after(seconds, &block)
        end

      rescue LoadError
        warn "WARNING: using the built-in Timeout class" unless RUBY_VERSION >= "1.9" || RUBY_PLATFORM =~ /java/

        require "timeout"

        def with_timeout(seconds, &block)
          Timeout.timeout(seconds, &block)
        end
      end

      def echo(command)
        puts "#{@name} >> #{command}"
      end

      def hear(command)
        puts "Server >> #{command}"
      end

      protected

      def ensure_connected
        connect unless connected?

        begin
          yield
        rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ECONNABORTED
          if reconnect
            yield
          else
            raise Errno::ECONNRESET
          end
        end
      end

      def logging(command)
        begin
          echo command

          t1 = Time.now
          yield
        ensure
          echo "%0.2fms" % ((Time.now - t1) * 1000)
        end
      end

    end

  end
end