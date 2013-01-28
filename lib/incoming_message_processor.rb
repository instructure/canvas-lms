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
  
  class SilentIgnoreError < StandardError; end
  class ReplyFromError < StandardError; end
  class UnknownAddressError < ReplyFromError; end
  class ReplyToLockedTopicError < ReplyFromError; end
  
  def self.bounce_message?(mail)
    mail.header.fields.any? do |field|
      case field.name

      # RFC-3834
      when 'Auto-Submitted' then field.value != 'no'

      # old klugey stuff uses this
      when 'Precedence' then ['bulk', 'list', 'junk'].include?(field.value)

      # Exchange sets this        
      when 'X-Auto-Response-Suppress' then true 

      # some other random headers I found that are easy to check
      when 'X-Autoreply', 'X-Autorespond', 'X-Autoresponder' then true

      # not a bounce header we care about
      else false
      end
    end

  end

  def self.utf8ify(string, encoding)
    encoding ||= 'UTF-8'
    encoding = encoding.upcase
    # change encoding; if it throws an exception (i.e. unrecognized encoding), just strip invalid UTF-8
    Iconv.conv('UTF-8//TRANSLIT//IGNORE', encoding, string) rescue TextHelper.strip_invalid_utf8(string)
  end

  def self.process_single(incoming_message, secure_id, message_id)
    return if IncomingMessageProcessor.bounce_message?(incoming_message)

    if incoming_message.multipart? && part = incoming_message.parts.find { |p| p.content_type.try(:match, %r{^text/html(;|$)}) }
      html_body = utf8ify(part.body.decoded, part.charset)
    end
    html_body = utf8ify(incoming_message.body.decoded, incoming_message.charset) if !incoming_message.multipart? && incoming_message.content_type.try(:match, %r{^text/html(;|$)})
    if incoming_message.multipart? && part = incoming_message.parts.find { |p| p.content_type.try(:match, %r{^text/plain(;|$)}) }
      body = utf8ify(part.body.decoded, part.charset)
    end
    body ||= utf8ify(incoming_message.body.decoded, incoming_message.charset)
    if !html_body
      self.extend TextHelper
      html_body = format_message(body).first
    end

    begin
      original_message = Message.find_by_id(message_id)
      # This prevents us from rebouncing users that have auto-replies setup -- only bounce something
      # that was sent out because of a notification.
      raise IncomingMessageProcessor::SilentIgnoreError unless original_message && original_message.notification_id
      raise IncomingMessageProcessor::SilentIgnoreError unless secure_id == original_message.reply_to_secure_id

      original_message.shard.activate do
        context = original_message.context
        user = original_message.user
        raise IncomingMessageProcessor::UnknownAddressError unless user && context && context.respond_to?(:reply_from)
        context.reply_from({
          :purpose => 'general',
          :user => user,
          :subject => utf8ify(incoming_message.subject, incoming_message.header[:subject].try(:charset)),
          :html => html_body,
          :text => body
        })
      end
    rescue IncomingMessageProcessor::ReplyFromError => error
      IncomingMessageProcessor.ndr(original_message, incoming_message, error)
    rescue IncomingMessageProcessor::SilentIgnoreError
      # ignore it
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

  def self.ndr(original_message, incoming_message, error)
    incoming_from = incoming_message.from.try(:first)
    incoming_subject = incoming_message.subject
    return unless incoming_from

    ndr_subject, ndr_body = IncomingMessageProcessor.ndr_strings(incoming_subject, error)
    outgoing_message = Message.new({
      :to => incoming_from,
      :from => HostUrl.outgoing_email_address,
      :subject => ndr_subject,
      :body => ndr_body,
      :delay_for => 0,
      :context => nil,
      :path_type => 'email',
      :from_name => "Instructure",
    })

    outgoing_message_delivered = false
    if original_message
      original_message.shard.activate do
        comch = CommunicationChannel.active.find_by_path_and_path_type(incoming_from, 'email')
        outgoing_message.communication_channel = comch
        outgoing_message.user = comch.try(:user)
        if outgoing_message.communication_channel && outgoing_message.user
          outgoing_message.save
          outgoing_message.deliver
          outgoing_message_delivered = true
        end
      end
    end

    unless outgoing_message_delivered
      # Can't use our usual mechanisms, so just try to send it once now
      begin 
        res = Mailer.deliver_message(outgoing_message)
      rescue => e
        # TODO: put some kind of error logging here?
      end
    end
  end

  def self.ndr_strings(subject, error)
    ndr_subject = ""
    ndr_body = ""
    case error
    when IncomingMessageProcessor::ReplyToLockedTopicError
      ndr_subject = I18n.t('lib.incoming_message_processor.locked_topic.subject', "Message Reply Failed: %{subject}", :subject => subject)
      ndr_body = I18n.t('lib.incoming_message_processor.locked_topic.body', <<-BODY, :subject => subject).strip_heredoc
        The message titled "%{subject}" could not be delivered because the discussion topic is locked. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

        Thank you,
        Canvas Support
      BODY
    else # including IncomingMessageProcessor::UnknownAddressError
      ndr_subject = I18n.t('lib.incoming_message_processor.failure_message.subject', "Message Reply Failed: %{subject}", :subject => subject)
      ndr_body = I18n.t('lib.incoming_message_processor.failure_message.body', <<-BODY, :subject => subject).strip_heredoc
        The message titled "%{subject}" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

        Thank you,
        Canvas Support
      BODY
    end

    [ndr_subject, ndr_body]
  end

end
