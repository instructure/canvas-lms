require 'thin'
require 'socket'

class SpecFriendlyThinServer
  def self.run(app, options = {})
    bind_address = options[:BindAddress] || IPSocket.getaddress(Socket.gethostname)
    port = options[:Port]
    @server = Thin::Server.new(bind_address, port, app)
    Thread.new {@server.start}
    for i in 0..MAX_SERVER_START_TIME
      begin
        s = TCPSocket.open(bind_address, port)
      rescue StandardError
        nil
      end
      break if s
      sleep 1
    end
  end

  def self.shutdown
    @server.stop if @server
    @server = nil
  end
end