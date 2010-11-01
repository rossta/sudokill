require 'em-http'
require File.dirname(__FILE__) + '/../lib/sudokl'

Sudokl::App::Logger.suppress_logging!

class FakeWebSocketClient < EM::Connection
  attr_writer :onopen, :onclose, :onmessage
  attr_reader :handshake_response, :packets

  def initialize
    @state = :new
    @packets = []
  end

  def receive_data(data)
    # puts "RECEIVE DATA #{data}"
    if @state == :new
      @handshake_response = data
      @onopen.call if @onopen
      @state = :open
    else
      @onmessage.call if @onmessage
      @packets << data
    end
  end

  def send(data)
    send_data("\x00#{data}\xff")
  end

  def unbind
    @onclose.call if @onclose
  end
end
