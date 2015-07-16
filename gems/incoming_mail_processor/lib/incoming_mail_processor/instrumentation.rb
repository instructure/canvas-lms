#
# Copyright (C) 2011-2015 Instructure, Inc.
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

module IncomingMailProcessor
  class Instrumentation
    def self.process
      unreads = []

      mailbox_accounts.each do |a|
        unreads << IncomingMailProcessor::IncomingMessageProcessor.create_mailbox(a).unprocessed_message_count
      end

      report_unreads(unreads)
    end

    def self.mailbox_accounts
      IncomingMailProcessor::IncomingMessageProcessor.mailbox_accounts
    end
    private_class_method :mailbox_accounts

    def self.report_unreads(unreads)
      result = Hash[mailbox_accounts.map(&:escaped_address).zip(unreads)]
      result.delete_if { |_k, v| v.nil? }
      result.each_pair do |identifier, count|
        name = "incoming_mail_processor.mailbox_queue_size.#{identifier}"
        CanvasStatsd::Statsd.gauge name, count
      end
    end
    private_class_method :report_unreads
  end
end
