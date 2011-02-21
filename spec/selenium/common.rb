#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'selenium/client'
require "socket"
require File.expand_path(File.dirname(__FILE__) + '/server')

SELENIUM_CONFIG = Setting.from_config("selenium") || {}
SERVER_IP = UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
SERVER_PORT = SELENIUM_CONFIG[:app_port] || 3002

module SeleniumTestsHelperMethods
  def setup_selenium
    Selenium::Client::Driver.new \
      :host => SELENIUM_CONFIG[:host] || "localhost",
      :port => SELENIUM_CONFIG[:port] || 4444,
      :browser => SELENIUM_CONFIG[:browser] || "Windows-Firefox",
      :url => "http://#{SERVER_IP}:#{SERVER_PORT}/",
      :timeout_in_second => 60
  end

  def self.start_webrick_server
    server = SpecFriendlyWEBrickServer
    app = Rack::Builder.new do
      use Rails::Rack::Debugger
      map '/' do

        use Rails::Rack::Static
        run ActionController::Dispatcher.new
      end
    end.to_app
    server.run(app, :Port => SERVER_PORT, :AccessLog => [])
    shutdown = lambda do
      server.shutdown
    end
    return shutdown
  end
end

shared_examples_for "all selenium tests" do

  include SeleniumTestsHelperMethods

  attr_reader :selenium_driver
  alias_method :page, :selenium_driver

  self.use_transactional_fixtures = false

  before(:each) do
    @selenium_driver.start_new_browser_session
  end
  
  append_after(:each) do
    @selenium_driver.close_current_browser_session
    ALL_MODELS.each &:delete_all
  end
  
  prepend_after(:each) do
    begin 
      if selenium_driver.session_started?
        selenium_driver.set_context "Ending example '#{self.description}'"
      end
    rescue Exception => e
      STDERR.puts "Problem while capturing system state" + e
    end
  end

  append_before(:each) do
    begin 
      if selenium_driver && selenium_driver.session_started?
        selenium_driver.set_context "Starting example '#{self.description}'"
      end
    rescue Exception => e
      STDERR.puts "Problem while setting context on example start" + e
    end
  end
  
  append_before(:all) do
    @webserver_shutdown = SeleniumTestsHelperMethods.start_webrick_server
  end

  append_after(:all) do
    @webserver_shutdown.call
  end
 
end

