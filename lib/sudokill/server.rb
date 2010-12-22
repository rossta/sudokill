module Sudokill
  PIPE = "|"
  SUDOKILL = 'Sudokill'

  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_accessor :controller

    def initialize(opts = {})
      @env        = (opts.delete(:env) || Sudokill.env).to_sym
      @host       = opts.delete(:host) || '0.0.0.0'
      @port       = (opts.delete(:port) || 44444).to_i
      @ws_host    = '0.0.0.0'
      @ws_port    = (opts.delete(:ws_port) || 8080).to_i
      @http_port  = (opts.delete(:http_port) || 4567).to_i
      @opts     = opts

      instances = (@opts[:instances] || 4).to_i
      instances.times do
        Controller.create!(opts.merge(:host => @host, :port => @port))
      end
      @controller = Controller.controllers.first
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }

        Sudokill::Controller.controllers.each do |app|
          app.channel = EM::Channel.new
        end

        EventMachine::start_server @host, @port, Client::Socket, :app => controller do |player|
          player.send_command "WAIT" unless @env == :test
        end

        EventMachine::start_server @ws_host, @ws_port, Client::WebSocket, :app => controller,
          :debug => @debug, :logging => true do |ws|
            ws.onopen {
              controller.subscribe(ws)
            }
        end

        EventMachine.add_periodic_timer(0.25) {
          controller.time_check
        }

        WebServer.run!(:bind => @host, :port => @http_port, :ws_port => @ws_port, :environment => @env)

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