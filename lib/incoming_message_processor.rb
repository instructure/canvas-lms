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
require 'iconv'

class IncomingMessageProcessor
  def self.utf8ify(string, encoding)
    encoding ||= 'UTF-8'
    encoding = encoding.upcase
    # change encoding; if it throws an exception (i.e. unrecognized encoding), just strip invalid UTF-8
    Iconv.conv('UTF-8//TRANSLIT//IGNORE', encoding, string) rescue Iconv.conv('UTF-8//IGNORE', 'UTF-8', string)
  end

  def self.process_single(message, secure_id, message_id)
    if message.multipart? && part = message.parts.find { |p| p.content_type.try(:match, %r{^text/html(;|$)}) }
      html_body = utf8ify(part.body.decoded, part.charset)
    end
    html_body = utf8ify(message.body.decoded, message.charset) if !message.multipart? && message.content_type.try(:match, %r{^text/html(;|$)})
    if message.multipart? && part = message.parts.find { |p| p.content_type.try(:match, %r{^text/plain(;|$)}) }
      body = utf8ify(part.body.decoded, part.charset)
    end
    body ||= utf8ify(message.body.decoded, message.charset)
    if !html_body
      self.extend TextHelper
      html_body = format_message(body).first
    end

    msg = Message.find_by_id(message_id)
    if msg
      msg.shard.activate do
        context = msg.context if secure_id == msg.reply_to_secure_id
        user = msg.user
        if user && context && context.respond_to?(:reply_from)
          context.reply_from({
            :purpose => 'general',
            :user => user,
            :subject => utf8ify(message.subject, message.header[:subject].try(:charset)),
            :html => html_body,
            :text => body
          })
        else
          IncomingMessageProcessor.ndr(message.from.first, message.subject) if message.from.try(:first)
        end
      end
    else
      IncomingMessageProcessor.ndr(message.from.first, message.subject) if message.from.try(:first)
    end
  end

  def self.process
    addr, domain = HostUrl.outgoing_email_address.split(/@/)
    regex = Regexp.new("#{Regexp.escape(addr)}\\+([0-9a-f]+)-(\\d+)@#{Regexp.escape(domain)}")
    Mailman::Application.run do
      to regex do
        begin
          IncomingMessageProcessor.process_single(message, params['captures'][0], params['captures'][1].to_i)
        rescue => e
          ErrorReport.log_exception(:default, e, :from => message.from.try(:first),
                                                 :to => message.to.to_s)
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
      :subject => I18n.t('lib.incoming_message_processor.failure_message.subject', "Message Reply Failed: %{subject}", :subject => subject),
      :body => I18n.t('lib.incoming_message_processor.failure_message.body', <<-BODY, :subject => subject),
The message titled "%{subject}" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

Thank you,
Canvas Support
      BODY
      :delay_for => 0,
      :context => nil,
      :path_type => 'email',
      :from_name => "Instructure"
    )
    message.deliver
  end

end
