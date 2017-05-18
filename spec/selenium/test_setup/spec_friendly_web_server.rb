#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
