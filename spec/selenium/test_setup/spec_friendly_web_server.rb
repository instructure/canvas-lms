require 'puma'
require 'httparty'

class SpecFriendlyWebServer
  class << self
    def bind_address
      '0.0.0.0'
    end

    def run(app, port:, timeout: 15)
      BlankSlateProtection.disable do
        start_server(app, port)
        wait_for_server(port, timeout)
      end
    end

    def start_server(app, port)
      @server = Puma::Server.new(app, Puma::Events.stdio)
      @server.add_tcp_listener(bind_address, port)
      Thread.new do
        begin
          @server.run
        rescue
          $stderr.puts "Unexpected server error: #{$ERROR_INFO.message}"
          exit! 1
        end
      end
    rescue Errno::EADDRINUSE, Errno::EACCES
      raise SeleniumDriverSetup::ServerStartupError, $ERROR_INFO.message
    end

    def wait_for_server(port, timeout)
      print "Starting web server..."
      max_time = Time.zone.now + timeout
      while Time.zone.now < max_time
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
      $stderr.puts "unable to start web server within #{timeout} seconds!"
      raise SeleniumDriverSetup::ServerStartupError # we'll rescue and retry on a new port
    end

    def shutdown
      @server.stop if @server
      @server = nil
    end
  end
end
