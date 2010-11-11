require 'em-http'
require File.dirname(__FILE__) + '/../lib/sudokoup'

Sudokoup::Logger.suppress_logging! unless ENV["SPEC_ENV"]=='debug'

class FakeWebSocketProxy < EM::Connection
  attr_writer :onopen, :onclose, :onmessage
  attr_reader :response, :packets

  def initialize
    @state = :new
    @packets = []
  end

  def receive_data(data)
    # puts "RECEIVE DATA #{data}"
    # if @state == :new
    #   @response = data
    #   @onopen.call if @onopen
    #   @state = :open
    # else
      @response = data
      @onmessage.call if @onmessage
      @packets << data
    # end
  end

  def send(data)
    send_data("\x00#{data}\xff")
  end

  def unbind
    @onclose.call if @onclose
  end
end
