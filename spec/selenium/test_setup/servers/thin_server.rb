require 'thin'
require 'httparty'

class SpecFriendlyThinServer
  def self.run(app, options = {})
    bind_address = options[:BindAddress] || IPSocket.getaddress(Socket.gethostname)
    port = options[:Port]
    @server = Thin::Server.new(bind_address, port, app, signals: false)
    Thin::Logging.logger = Rails.logger
    Thread.new do
      Thread.current.abort_on_exception = true
      @server.start
    end
    max_time = Time.now + MAX_SERVER_START_TIME
    print "Starting thin server..."
    while Time.now < max_time
      begin
        response = HTTParty.get("http://#{bind_address}:#{port}/health_check")
        if response.success?
          puts " Done!"
          return
        end
      rescue
        nil
      end
      print "."
      sleep 1
    end
    puts "Failed!"
    $stderr.puts "unable to start thin server within #{MAX_SERVER_START_TIME} seconds!"
    exit! 1
  end

  def self.shutdown
    @server.stop if @server
    @server = nil
  end
end
