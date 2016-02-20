require 'thin'
require 'httparty'

class SpecFriendlyThinServer
  def self.run(app, options = {})
    bind_address = options[:BindAddress] || IPSocket.getaddress(Socket.gethostname)
    port = options[:Port]
    start_server(app, bind_address, port)
    wait_for_server(bind_address, port)
  end

  def self.start_server(app, bind_address, port)
    @server = Thin::Server.new(bind_address, port, app, signals: false)
    Thin::Logging.logger = Rails.logger
    Thread.new do
      Thread.current.abort_on_exception = true

      max_attempts = 2
      retry_count = 0

      begin
        @server.start
      rescue
        raise unless $ERROR_INFO.message =~ /no acceptor/ && retry_count <= max_attempts
        puts "Got `#{$ERROR_INFO.message}`, retrying"
        sleep 1
        retry_count += 1
        retry
      end
    end
  end

  def self.wait_for_server(bind_address, port)
    print "Starting thin server..."
    max_time = Time.now + MAX_SERVER_START_TIME
    while Time.now < max_time
      response = HTTParty.get("http://#{bind_address}:#{port}/health_check") rescue nil
      if response && response.success?
        SeleniumDriverSetup.disallow_requests!
        puts " Done!"
        return
      end
      print "."
      sleep 1
    end
    puts "Failed!"
    $stderr.puts "unable to start thin server within #{MAX_SERVER_START_TIME} seconds!"
    raise SeleniumDriverSetup::ServerStartupError
  end

  def self.shutdown
    @server.stop if @server
    @server = nil
  end
end
