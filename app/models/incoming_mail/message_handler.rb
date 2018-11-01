#
# Copyright (C) 2014 - present Instructure, Inc.
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
      secure_id, original_message_id, timestamp = parse_tag(tag)
      return unless original_message_id

      original_message = get_original_message(original_message_id, timestamp)
      # This prevents us from rebouncing users that have auto-replies setup -- only bounce something
      # that was sent out because of a notification.
      return unless original_message && original_message.notification_id
      return unless valid_secure_id?(original_message_id, secure_id)

      from_channel = nil
      original_message.shard.activate do
        begin
          context = original_message.context
          user = original_message.user
          raise IncomingMail::Errors::UnknownAddress unless valid_user_and_context?(context, user)
          from_channel = sent_from_channel(user, incoming_message)
          raise IncomingMail::Errors::UnknownSender unless from_channel
          Rails.cache.fetch(['incoming_mail_reply_from', context, incoming_message.message_id].cache_key, expires_in: 7.days) do
            context.reply_from({
                                 :purpose => 'general',
                                 :user => user,
                                 :subject => IncomingMailProcessor::IncomingMessageProcessor.utf8ify(incoming_message.subject, incoming_message.header[:subject].try(:charset)),
                                 :html => html_body,
                                 :text => body
                               })
            true
          end
        rescue IncomingMail::Errors::ReplyFrom => error
          bounce_message(original_message, incoming_message, error, outgoing_from_address, from_channel)
        rescue => e
          Canvas::Errors.capture_exception("IncomingMailProcessor", e)
        end
      end
    end

    private

    def bounce_message(original_message, incoming_message, error, outgoing_from_address, from_channel)
      incoming_from = from_channel.try(:path) || incoming_message.from.try(:first)
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
        comch = from_channel || CommunicationChannel.active.email.by_path(incoming_from).first
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
          Mailer.deliver(Mailer.create_message(outgoing_message))
        rescue => e
          # TODO: put some kind of error logging here?
        end
      end
    end

    def bounce_message_strings(subject, error)
      ndr_subject = ""
      ndr_body = ""
      case error
        when IncomingMail::Errors::ReplyToDeletedDiscussion
          ndr_subject = I18n.t("Undelivered message")
          ndr_body = I18n.t(<<-BODY, :subject => subject).gsub(/^ +/, '')
          The message titled "%{subject}" could not be delivered because the discussion topic has been deleted. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

          Thank you,
          Canvas Support
          BODY
        when IncomingMail::Errors::ReplyToLockedTopic
          ndr_subject = I18n.t("Undelivered message")
          ndr_body = I18n.t('lib.incoming_message_processor.locked_topic.body', <<-BODY, :subject => subject).gsub(/^ +/, '')
          The message titled "%{subject}" could not be delivered because the discussion topic is locked. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

          Thank you,
          Canvas Support
          BODY
        when IncomingMail::Errors::UnknownSender
          ndr_subject = I18n.t("Undelivered message")
          ndr_body = I18n.t(<<-BODY, :subject => subject).gsub(/^ +/, '')
          The message you sent with the subject line "%{subject}" was not delivered. To reply to Canvas messages from this email, it must first be a confirmed communication channel in your Canvas profile. Please visit your profile and resend the confirmation email for this email address [See https://community.canvaslms.com/docs/DOC-2281]. You may also contact this person via the Canvas Inbox [See https://community.canvaslms.com/docs/DOC-2670].

          Thank you,
          Canvas Support
          BODY
        else # including IncomingMessageProcessor::UnknownAddressError
          ndr_subject = I18n.t("Undelivered message")
          ndr_body = I18n.t('lib.incoming_message_processor.failure_message.body', <<-BODY, :subject => subject).gsub(/^ +/, '')
          The message titled "%{subject}" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

          Thank you,
          Canvas Support
          BODY
      end

      [ndr_subject, ndr_body]
    end

    def valid_secure_id?(original_message_id, secure_id)
      Canvas::Security.verify_hmac_sha1(secure_id, original_message_id)
    end

    def valid_user_and_context?(context, user)
      user && context && context.respond_to?(:reply_from)
    end

    def sent_from_channel(user, incoming_message)
      from_addresses = ((incoming_message.from || []) + (incoming_message.reply_to || [])).uniq
      user && from_addresses.lazy.map {|addr| user.communication_channels.active.email.by_path(addr).first}.first
    end

    def parse_tag(tag)
      match = tag.match /^(\h+)-([0-9~]+)(?:-([0-9]+))?$/
      return match[1], match[2], match[3] if match
    end

    def get_original_message(original_message_id, timestamp)
      if timestamp
        Message.where(id: original_message_id).at_timestamp(timestamp).first
      else
        Message.where(id: original_message_id).first
      end
    end
  end
end
