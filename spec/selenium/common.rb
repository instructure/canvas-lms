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

SELENIUM_CONFIG = Setting.from_config("selenium") || {
    :host => "localhost", :port => 4444 }
SERVER_IP = UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
SERVER_PORT = 3002
MAX_SERVER_START_TIME = 30

module SeleniumTestsHelperMethods
  def setup_selenium(selenium_env)
    Selenium::Client::Driver.new \
      :host => SELENIUM_CONFIG[:host],
      :port => SELENIUM_CONFIG[:port],
      :browser => selenium_env,
      :url => "http://#{SERVER_IP}:#{SERVER_PORT}/",
      :timeout_in_second => 60
  end
  
  def self.start_webrick_server
    domain_conf_path = File.expand_path(File.dirname(__FILE__) + '/../../config/domain.yml')
    domain_conf = YAML.load_file(domain_conf_path)
    old_domain = domain_conf[RAILS_ENV]["domain"]
    domain_conf[RAILS_ENV]["domain"] = "#{SERVER_IP}:#{SERVER_PORT}"
    File.open(domain_conf_path, 'w') { |f| YAML.dump(domain_conf, f) }
    server_pid = fork do
      exec(File.expand_path(File.dirname(__FILE__) +
          "/../../script/server -p #{SERVER_PORT} -e #{RAILS_ENV}"))
    end
    for i in 0..MAX_SERVER_START_TIME
      s = TCPSocket.open('127.0.0.1', SERVER_PORT) rescue nil
      break if s
      sleep 1
    end
    raise "Failed starting script/server" unless s
    s.close
    closed = false
    shutdown = lambda do
      unless closed
        Process.kill 'KILL', server_pid
        Process.wait server_pid
        domain_conf[RAILS_ENV]["domain"] = old_domain
        File.open(domain_conf_path, 'w') { |f| YAML.dump(domain_conf, f) }
        closed = true
      end
    end
    at_exit { shutdown.call }
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

