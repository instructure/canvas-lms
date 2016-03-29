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

require 'net/imap'
require File.expand_path('../configurable_timeout', __FILE__)

module IncomingMailProcessor

  class ImapMailbox
    include ConfigurableTimeout

    UsedImapMethods = [:login, :logout, :disconnect, :select, :search, :fetch, :expunge, :store, :list, :create, :copy]

    attr_accessor :server, :port, :ssl, :username, :password, :folder, :filter

    def initialize(options = {})
      @server   = options.fetch(:server, "")
      @port     = options.fetch(:port, 993)
      @ssl      = options.fetch(:ssl, true)
      @username = options.fetch(:username, "")
      @password = options.fetch(:password, "")
      @folder   = options.fetch(:folder, "INBOX")
      @filter   = Array(options.fetch(:filter, "ALL"))
    end

    def connect
      @imap = with_timeout { Net::IMAP.new(@server, :port => @port, :ssl => @ssl) }
      wrap_with_timeout(@imap, UsedImapMethods)
      @imap.login(@username, @password)
    end

    def disconnect
      @imap.logout
      @imap.disconnect
    rescue
    end

    def each_message(opts={})
      @imap.select(@folder)
      message_ids = @imap.search(@filter)
      message_ids = message_ids.select{|id| id % opts[:stride] == opts[:offset]} if opts[:stride] && opts[:offset]
      message_ids.each do |message_id|
        body = @imap.fetch(message_id, "RFC822")[0].attr["RFC822"]
        yield message_id, body
      end
      @imap.expunge
    end

    def delete_message(message_id)
      @imap.store(message_id, "+FLAGS", Net::IMAP::DELETED)
    end

    def move_message(message_id, target_folder)
      existing = @imap.list("", target_folder)
      if !existing || existing.empty?
        @imap.create(target_folder)
      end
      @imap.copy(message_id, target_folder)
      delete_message(message_id)
    end

    def unprocessed_message_count
      connect
      @imap.select("INBOX")
      length = @imap.search(["X-GM-RAW", "label:unread"]).length
      disconnect
      length
    end
  end

end
