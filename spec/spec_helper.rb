require File.dirname(__FILE__) + '/../lib/sudocoup'
Sudocoup::Logger.suppress_logging! unless ENV["SPEC_ENV"]=='debug'

require 'json'
require 'pp'
require 'em-http'

class FakeDeferrable
  def callback(&block)
    @block = block
  end
  def succeed
    @block.call
  end
end

class FakeSocketClient < EventMachine::Connection
  attr_writer :onopen, :onclose, :onmessage
  attr_reader :data
  def initialize
    @state = :new
    @data = []
  end

  def receive_data(data)
    log "RECEIVE DATA #{data}"
    @data << data
    if @state == :new
      @onopen.call if @onopen
      @state = :open
    else
      @onmessage.call(data) if @onmessage
    end
  end

  def unbind
    @onclose.call if @onclose
  end
end

class FakeWebSocketClient < EM::Connection
  attr_writer :onopen, :onclose, :onmessage
  attr_reader :handshake_response, :packets, :request

  def initialize
    @state = :new
    @packets = []
    @request = {
      :port => 80,
      :method => "GET",
      :path => "/demo",
      :headers => {
        'Host' => 'example.com',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
        'Sec-WebSocket-Protocol' => 'sample',
        'Upgrade' => 'WebSocket',
        'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
        'Origin' => 'http://example.com'
      },
      :body => '^n:ds[4U'
    }
  end

  def receive_data(data)
    log "RECEIVE DATA #{data}"
    if @state == :new
      @handshake_response = data
      @onopen.call if @onopen
      @state = :open
    else
      @onmessage.call(data) if @onmessage
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

def failed
  EventMachine.stop
  fail
end

def format_request(r)
  data = "#{r[:method]} #{r[:path]} HTTP/1.1\r\n"
  header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
  data << [header_lines, '', r[:body]].join("\r\n")
  data
end

def format_response(r)
  data = "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
  header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
  data << [header_lines, '', r[:body]].join("\r\n")
  data
end

def handler(request, secure = false)
  EM::WebSocket::HandlerFactory.build(format_request(request), secure)
end

def send_handshake(response)
  simple_matcher do |given|
    given.handshake.lines.sort == format_response(response).lines.sort
  end
end

def mock_player(attrs = {})
  mock(Sudocoup::Client::Socket, {
    :number => 1,
    :current_time => 0,
    :name => "Player",
    :reset => nil,
    :send_command =>nil,
    :send => nil,
    :time_left? => true,
    :to_json => %Q|{"number":1}|
  }.merge(attrs))
end
