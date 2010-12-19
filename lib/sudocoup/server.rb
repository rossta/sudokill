module Sudocoup
  PIPE = "|"
  SUDOKOUP = 'Sudocoup'

  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_accessor :controller

    def initialize(opts = {})
      @host     = opts.delete(:host) || '0.0.0.0'
      @port     = (opts.delete(:port) || 44444).to_i
      @ws_host  = '0.0.0.0'
      @ws_port  = (opts.delete(:ws_port) || 8080).to_i
      @opts     = opts

      @controller = Controller.new(opts)
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }

        controller.channel  = EM::Channel.new

        EventMachine::start_server @host, @port, Client::Socket, :app => controller do |player|
          @controller.call :new_player, :player => player
        end

        EventMachine::start_server @ws_host, @ws_port, Client::WebSocket, :app => controller,
          :debug => @debug, :logging => true do |ws|
            ws.onopen { ws.sid = controller.channel.subscribe { |msg| ws.send msg } }
        end

        EventMachine.add_periodic_timer(0.25) { controller.time_check }

        log_server_started
      end
    end

    def stop
      log "Stopping server"
      controller.close
      EventMachine.stop
    end

    def trigger(method, *args)
      controller.call method, *args
    end

    protected

    def log_server_started
      log "Listening for players on #{host_name(@host)}:#{@port}"
      log "Listening for websockets at ws://#{host_name(@ws_host)}:#{@ws_port}"
    end

    def host_name(host)
      host == "0.0.0.0" ? 'localhost' : host
    end
  end
end