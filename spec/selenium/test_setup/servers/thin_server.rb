require 'thin'
require 'httparty'

class SpecFriendlyThinServer
  def self.run(app, options = {})
    bind_address = options[:BindAddress] || IPSocket.getaddress(Socket.gethostname)
    port = options[:Port]
    @port_ok = true
    BlankSlateProtection.disable do
      start_server(app, bind_address, port)
      wait_for_server(bind_address, port)
    end
  end

  class NoAcceptorError
    def self.===(exception)
      exception.message =~ /no acceptor/
    end
  end

  def self.start_server(app, bind_address, port)
    @server = Thin::Server.new(bind_address, port, app, signals: false)
    Thin::Logging.logger = Rails.logger
    Thread.new do
      begin
        SeleniumDriverSetup.with_retries error_class: NoAcceptorError, failure_proc: -> { @port_ok = false } do
          @server.start
        end
      rescue # anything else just bail w/o retrying
        $stderr.puts "Unexpected thin server error: #{$ERROR_INFO.message}"
        exit! 1
      end
    end
  end

  def self.wait_for_server(bind_address, port)
    print "Starting thin server..."
    max_time = Time.now + MAX_SERVER_START_TIME
    while Time.now < max_time && @port_ok
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
    raise SeleniumDriverSetup::ServerStartupError # we'll rescue and retry on a new port
  end

  def self.shutdown
    @server.stop if @server
    @server = nil
  end
end
