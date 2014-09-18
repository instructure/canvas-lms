#
# Copyright (C) 2014 Instructure, Inc.
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

module IncomingMail
  class MessageHandler
    def handle(outgoing_from_address, body, html_body, incoming_message, tag)
      secure_id, original_message_id = parse_tag(tag)
      raise IncomingMail::Errors::SilentIgnore unless original_message_id

      original_message = Message.where(id: original_message_id).first
      # This prevents us from rebouncing users that have auto-replies setup -- only bounce something
      # that was sent out because of a notification.
      raise IncomingMail::Errors::SilentIgnore unless original_message && original_message.notification_id
      raise IncomingMail::Errors::SilentIgnore unless valid_secure_id?(original_message, secure_id)

      original_message.shard.activate do

        context = original_message.context
        user = original_message.user
        raise IncomingMail::Errors::UnknownAddress unless valid_user_and_context?(context, user)
        context.reply_from({
                               :purpose => 'general',
                               :user => user,
                               :subject => utf8ify(incoming_message.subject, incoming_message.header[:subject].try(:charset)),
                               :html => html_body,
                               :text => body
                           })
      end
    rescue IncomingMail::Errors::ReplyFrom => error
      bounce_message(original_message, incoming_message, error, outgoing_from_address)
    rescue IncomingMail::Errors::SilentIgnore
      #do nothing
    end

    private

    def bounce_message(original_message, incoming_message, error, outgoing_from_address)
      incoming_from = incoming_message.from.try(:first)
      incoming_subject = incoming_message.subject
      return unless incoming_from

      ndr_subject, ndr_body = bounce_message_strings(incoming_subject, error)
      outgoing_message = Message.new({
                                         :to => incoming_from,
                                         :from => outgoing_from_address,
                                         :subject => ndr_subject,
                                         :body => ndr_body,
                                         :delay_for => 0,
                                         :context => nil,
                                         :path_type => 'email',
                                         :from_name => "Instructure",
                                     })

      outgoing_message_delivered = false

      original_message.shard.activate do
        comch = CommunicationChannel.active.where(path: incoming_from, path_type: 'email').first
        outgoing_message.communication_channel = comch
        outgoing_message.user = comch.try(:user)
        if outgoing_message.communication_channel
          outgoing_message.save
          outgoing_message.deliver
          outgoing_message_delivered = true
        end
      end

      unless outgoing_message_delivered
        # Can't use our usual mechanisms, so just try to send it once now
        begin
          res = Mailer.create_message(outgoing_message).deliver
        rescue => e
          # TODO: put some kind of error logging here?
        end
      end
    end

    def bounce_message_strings(subject, error)
      ndr_subject = ""
      ndr_body = ""
      case error
        when IncomingMail::Errors::ReplyToLockedTopic
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

    def valid_secure_id?(original_message, secure_id)
      Canvas::Security.verify_hmac_sha1(secure_id, original_message.global_id.to_s)
    end

    def valid_user_and_context?(context, user)
      user && context && context.respond_to?(:reply_from)
    end

    # MOVE!
    def utf8ify(string, encoding)
      encoding ||= 'UTF-8'
      encoding = encoding.upcase
      # change encoding; if it throws an exception (i.e. unrecognized encoding), just strip invalid UTF-8
      Iconv.conv('UTF-8//TRANSLIT//IGNORE', encoding, string) rescue TextHelper.strip_invalid_utf8(string)
    end

    def parse_tag(tag)
      match = tag.match /^(\h+)-(\d+)$/
      return match[1], match[2].to_i if match
    end
  end
end
