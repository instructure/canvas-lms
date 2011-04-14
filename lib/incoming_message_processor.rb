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

class IncomingMessageProcessor
  def self.process
    addr, domain = HostUrl.outgoing_email_address.split(/@/)
    regex = Regexp.new("#{Regexp.escape(addr)}\\+([0-9a-f]+)-(\\d+)@#{Regexp.escape(domain)}")
    Mailman::Application.run do
      to regex do
        html_body = (message.parts.find { |p| p.content_type = 'text/html' }).body.decoded if message.multipart?
        html_body = message.body.decoded if !message.multipart? && message.content_type = 'text/html'
        body = (message.parts.find { |p| p.content_type = 'text/plain' }).body.decoded if message.multipart?
        body ||= message.body.decoded
        if !html_body
          self.extend TextHelper
          html_body = format_message(body).first
        end

        msg = Message.find_by_id(params['captures'][1].to_i)
        context = msg.context if msg && params['captures'][0] == msg.reply_to_secure_id
        user = msg.user
        begin
          if user && context && context.respond_to?(:reply_from)
            context.reply_from({
              :purpose => 'general',
              :user => user,
              :subject => message.subject,
              :html => html_body,
              :text => body
            })
          else
            IncomingMessageProcessor.ndr(message.from.first, message.subject)
          end
        rescue => e
          ErrorLogging.log_exception(:default, e, :message => "Incoming Message Failed", :params => {:from => message.from.first, :to => message.to} )
        end
      end
      default do
        # TODO: Add bounce processing and handling of other email to the default notification address.
      end
    end
  end

  def self.ndr(from, subject)
    message = Message.create!(
      :to => from,
      :from => HostUrl.outgoing_email_address,
      :subject => "Message Reply Failed: #{subject}",
      :body => %{The message titled "#{subject}" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

Thank you,
Canvas Support
      },
      :delay_for => 0,
      :context => nil,
      :path_type => 'email',
      :from_name => "Instructure"
    )
    message.deliver
  end

end
