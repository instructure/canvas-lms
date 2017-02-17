require 'thin'
require 'httparty'

class SpecFriendlyThinServer
  class NoAcceptorError
    def self.===(exception)
      exception.message =~ /no acceptor/
    end
  end

  class << self
    def bind_address
      '0.0.0.0'
    end

    def run(app, port:, timeout: 15)
      @port_ok = true
      BlankSlateProtection.disable do
        start_server(app, port)
        wait_for_server(port, timeout)
      end
    end

    def start_server(app, port)
      @server = Thin::Server.new(bind_address, port, app, signals: false)
      Thin::Logging.logger = Rails.logger
      Thread.new do
        begin
          SeleniumDriverSetup.with_retries error_class: NoAcceptorError, failure_proc: -> { @port_ok = false } do
            @server.start
          end
        rescue StandardError # anything else just bail w/o retrying
          $stderr.puts "Unexpected thin server error: #{$ERROR_INFO.message}"
          exit! 1
        end
      end
    end

    def wait_for_server(port, timeout)
      print "Starting thin server..."
      max_time = Time.zone.now + timeout
      while Time.zone.now < max_time && @port_ok
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
      $stderr.puts "unable to start thin server within #{timeout} seconds!"
      raise SeleniumDriverSetup::ServerStartupError # we'll rescue and retry on a new port
    end

    def shutdown
      @server.stop if @server
      @server = nil
    end
  end
end
