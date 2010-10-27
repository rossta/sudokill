module Sudokl

  module View

    class Controller

      def initialize(opts = {})
        @host = opts[:host] || '127.0.0.1'
        @port = opts[:port] || 55555
        @sock = opts[:sock] || 8080
        @debug = opts[:debug] || true
        @proxy = nil
      end

      def connect!
        EventMachine.run do

          trap("TERM") { Sudokl::View::WebSocket.stop }
          trap("INT")  { Sudokl::View::WebSocket.stop }

          @proxy = EM.connect @host, @port, Sudokl::View::Proxy

          Sudokl::View::WebSocket.start(:host => "0.0.0.0", :port => @sock, :debug => @debug) do |ws|

            ws.onopen    {
              @proxy.websocket = ws
            }

            ws.onmessage { |msg|
              @proxy.send_data(msg)
            }

            ws.onclose   {
              ws.send "Closing time"
              puts "WebSocket closed"
            }

          end
        end
      end

    end
  end
end