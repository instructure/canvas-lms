#
# Copyright (C) 2013 Instructure, Inc.
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

require 'net/pop'
require File.expand_path('../configurable_timeout', __FILE__)

module IncomingMailProcessor

  class Pop3Mailbox
    include ConfigurableTimeout

    UsedPopMethods = [:start, :mails, :finish]

    attr_accessor :server, :port, :ssl, :username, :password

    def initialize(options = {})
      @server   = options.fetch(:server, "")
      @port     = options.fetch(:port, 995)
      @ssl      = options.fetch(:ssl, true)
      @username = options.fetch(:username, "")
      @password = options.fetch(:password, "")
    end

    def connect
      @pop = with_timeout { Net::POP3.new(server, port) }
      wrap_with_timeout(@pop, UsedPopMethods)
      @pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if ssl
      @pop.start(username, password)
    end

    def disconnect
      @pop.finish
    rescue
    end

    def each_message
      mails = @pop.mails
      mails.each do |message|
        yield message, message.pop
      end
    end

    def delete_message(pop_message)
      with_timeout { pop_message.delete }
    end

    def move_message(pop_message, target_folder)
      # pop can't do this -- just delete the message
      delete_message(pop_message)
    end
  end

end