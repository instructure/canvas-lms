require 'thin'
require 'socket'

class SpecFriendlyThinServer
  def self.run(app, port, options = {})
    ip = IPSocket.getaddress(Socket.gethostname)
    @server = Thin::Server.new(ip, port, app)
    Thread.new {@server.start}
    for i in 0..MAX_SERVER_START_TIME
      s = TCPSocket.open(ip, port) rescue nil
      break if s
      sleep 1
    end
  end

  def self.shutdown
    @server.stop if @server
    @server = nil
  end
end