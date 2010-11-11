module Sudokoup

  class ViewHandler < EventMachine::Connection
    attr_accessor :app, :websocket

    def post_init
    end

    def receive_data(data)
      (@buf ||= '') << data
      if line = @buf.slice!(/(.+)\r?\n/)
        case line
        when /NEW CONNECTION/
          json = %Q|{"action":"CREATE","values":#{@app.board.to_json}}|
          send_data(json + "\n")
        when /UPDATE/
          json = %Q|{"action":"UPDATE","value":#{@app.current_move.to_json}}|
          send_data(json + "\n")
        end
      end
    end

    def unbind
    end

    protected

    def ensure_app
      raise "Instance of Sudokoup::Server not defined" unless @app
    end

  end
end