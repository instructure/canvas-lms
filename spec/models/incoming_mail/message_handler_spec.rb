# frozen_string_literal: true

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

describe IncomingMail::MessageHandler do
  specs_require_sharding

  let(:outgoing_from_address) { "no-reply@example.com" }
  let(:body) { "Hello" }
  let(:html_body) { "Hello" }
  let(:original_message_id) { Shard.short_id_for(@shard1.global_id_for(42)) }
  let(:timestamp) { DateTime.parse("2018-10-16").to_i.to_s }
  let(:secure_id) { "123abc" }
  let(:tag) { "#{secure_id}-#{original_message_id}-#{timestamp}" }
  let(:shard) do
    shard = double("shard")
    allow(shard).to receive(:activate).and_yield
    shard
  end
  let_once(:user) do
    user_with_pseudonym
    communication_channel(@user, { username: "lucy@example.com", active_cc: true })
    @user
  end
  let(:context) { double("context", reply_from: nil) }

  let(:original_message_attributes) do
    {
      notification_id: 1,
      shard:,
      context:,
      user:,
      global_id: 1,
      to: "lucy@example.com"
    }
  end

  let(:incoming_message_attributes) do
    {
      subject: "some subject",
      header: {
        subject: double("subject", charset: "utf8")
      },
      from: ["lucy@example.com"],
      reply_to: ["lucy@example.com"],
      message_id: 1,
    }
  end

  let(:incoming_message) { double("incoming message", incoming_message_attributes) }
  let(:original_message) { double("original message", original_message_attributes) }

  before do
    allow(CanvasSecurity).to receive(:verify_hmac_sha1).and_return(true)
    allow_any_instance_of(Message).to receive(:save_using_update_all).and_return(true)
  end

  describe "#route" do
    it "activates the message's shard" do
      enable_cache do
        allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
        expect(shard).to receive(:activate)

        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
      end
    end

    it "calls reply from on the message's context" do
      enable_cache do
        expect(context).to receive(:reply_from)
        allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
      end
    end

    it "is idempotent (via caching)" do
      enable_cache do
        expect(context).to receive(:reply_from).once
        allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
      end
    end

    it "Sets html to nil if it is too long but keeps the plain text" do
      # Set the max text length to 10
      allow(ActiveRecord::Base).to receive(:maximum_text_length).and_return(10)

      expected_reply_from_parameters = {
        purpose: "general",
        user: original_message.user,
        subject: IncomingMailProcessor::IncomingMessageProcessor.utf8ify(incoming_message.subject, incoming_message.header[:subject].try(:charset)),
        html: nil,
        text: "a"
      }

      expect(context).to receive(:reply_from).with(expected_reply_from_parameters)
      allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)

      subject.handle(outgoing_from_address, "a", "b" * (ActiveRecord::Base.maximum_text_length + 1), incoming_message, tag)
    end

    context "when a reply from error occurs" do
      context "silent failures" do
        it "silently fails on no message notification id" do
          message = double("original message without notification id", original_message_attributes.merge(notification_id: nil))
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(message)
          expect(Mailer).not_to receive(:create_message)
          expect(message.context).not_to receive(:reply_from)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "silently fails on invalid secure id" do
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
          allow(CanvasSecurity).to receive(:verify_hmac_sha1).and_return(false)
          expect(Mailer).not_to receive(:create_message)
          expect(original_message.context).not_to receive(:reply_from)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "silently fails if the original message is missing" do
          expect(Message).to receive(:where).with(id: original_message_id).and_return(double(first: nil))
          expect_any_instance_of(Message).not_to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, "#{secure_id}-#{original_message_id}")
        end

        it "silently fails if the address tag is invalid" do
          expect(Message).not_to receive(:where)
          expect_any_instance_of(Message).not_to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, "#{secure_id}-not-an-id")
        end

        it "silently fails if the message is not from one of the original recipient's email addresses" do
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
          expect_any_instance_of(Message).not_to receive(:deliver)
          expect(Account.site_admin).to receive(:feature_enabled?).with(:notification_service).and_return(false)
          expect(original_message.context).not_to receive(:reply_from)
          message = double("incoming message with bad from",
                           incoming_message_attributes.merge(from: ["not_lucy@example.com"],
                                                             reply_to: ["also_not_lucy@example.com"]))
          subject.handle(outgoing_from_address, body, html_body, message, tag)
        end

        it "raises BlankMessage for empty message" do
          message = double("original message without notification id", original_message_attributes)
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(message)
          expect(original_message.context).not_to receive(:reply_from)
          subject.handle(outgoing_from_address, " ", html_body, incoming_message, tag)
        end
      end

      context "bounced messages" do
        it "bounces if user is suspended" do
          @pseudonym.update!(workflow_state: "suspended")
          @pseudonym.reload
          user.reload
          allow(InstStatsd::Statsd).to receive(:increment)
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
          # by not receiving reply_from we make sure that it is not processed as a reply
          expect(original_message.context).not_to receive(:reply_from)
          # make sure message was bounced
          email_subject = "Undelivered message"
          body = <<~TEXT.strip
            The message you sent with the subject line "some subject" was not delivered because your account has been suspended.

            Thank you,
            Canvas Support
          TEXT

          message_attributes = {
            to: "lucy@example.com",
            from: "no-reply@example.com",
            subject: email_subject,
            body:,
            delay_for: 0,
            context: nil,
            path_type: "email",
            from_name: "Instructure",
          }
          expected_bounce_message = Message.new(message_attributes)
          expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
          expect(expected_bounce_message).to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          expect(InstStatsd::Statsd).to have_received(:increment).with("incoming_mail_processor.message_processing_error.user_suspended")
        end

        it "bounces if user is missing" do
          message = double("original message without user", original_message_attributes.merge(user: nil))
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(message)
          expect_any_instance_of(Message).to receive(:deliver)
          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "bounces the message on invalid context" do
          message = double("original message with invalid context", original_message_attributes.merge({ context: double("context") }))
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(message)
          expect_any_instance_of(Message).to receive(:save)
          expect_any_instance_of(Message).to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "does not send a message if the incoming message has no from" do
          invalid_incoming_message = double("invalid incoming message", incoming_message_attributes.merge(from: nil, reply_to: nil))
          allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
          expect_any_instance_of(Message).not_to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, invalid_incoming_message, tag)
        end

        context "with a generic generic_error" do
          it "constructs the message correctly" do
            message = double("original message without user", original_message_attributes.merge(context: nil))
            allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(message)
            allow(subject).to receive(:get_ref_uuid).and_return("TestRef")

            email_subject = "Undelivered message"
            body = <<~TEXT.strip
              The message titled "some subject" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

              Thank you,
              Canvas Support

              Reference: TestRef
            TEXT

            message_attributes = {
              to: "lucy@example.com",
              from: "no-reply@example.com",
              subject: email_subject,
              body:,
              delay_for: 0,
              context: nil,
              path_type: "email",
              from_name: "Instructure",
            }
            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "with a locked discussion topic generic_error" do
          it "constructs the message correctly" do
            allow(InstStatsd::Statsd).to receive(:increment)
            allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
            expect(context).to receive(:reply_from).and_raise(IncomingMail::Errors::ReplyToLockedTopic.new)

            email_subject = "Undelivered message"
            body = <<~TEXT.strip
              The message titled "some subject" could not be delivered because the discussion topic is locked. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

              Thank you,
              Canvas Support
            TEXT

            message_attributes = {
              to: "lucy@example.com",
              from: "no-reply@example.com",
              subject: email_subject,
              body:,
              delay_for: 0,
              context: nil,
              path_type: "email",
              from_name: "Instructure",
            }
            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
            expect(InstStatsd::Statsd).to have_received(:increment).with("incoming_mail_processor.message_processing_error.reply_to_locked_topic")
          end
        end

        context "with an IncomingMail::Errors::InvalidParticipant error" do
          it "sends the appropriate message" do
            allow(InstStatsd::Statsd).to receive(:increment)
            allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
            expect(context).to receive(:reply_from).and_raise(IncomingMail::Errors::InvalidParticipant.new)

            email_subject = "Undelivered message"
            body = <<~TEXT.strip
              The message you sent with the subject line "some subject" was not delivered because you are not a valid participant in the conversation.

              Thank you,
              Canvas Support
            TEXT

            message_attributes = {
              to: "lucy@example.com",
              from: "no-reply@example.com",
              subject: email_subject,
              body:,
              delay_for: 0,
              context: nil,
              path_type: "email",
              from_name: "Instructure",
            }

            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
            expect(InstStatsd::Statsd).to have_received(:increment).with("incoming_mail_processor.message_processing_error.invalid_participant")
          end
        end

        context "with a generic reply to error" do
          it "constructs the message correctly" do
            allow(InstStatsd::Statsd).to receive(:increment)
            allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)
            allow(subject).to receive(:get_ref_uuid).and_return("TestRef")
            expect(context).to receive(:reply_from).and_raise(IncomingMail::Errors::UnknownAddress.new)

            email_subject = "Undelivered message"
            body = <<~TEXT.strip
              The message titled "some subject" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

              Thank you,
              Canvas Support

              Reference: TestRef
            TEXT

            message_attributes = {
              to: "lucy@example.com",
              from: "no-reply@example.com",
              subject: email_subject,
              body:,
              delay_for: 0,
              context: nil,
              path_type: "email",
              from_name: "Instructure",
            }
            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
            expect(InstStatsd::Statsd).to have_received(:increment).with("incoming_mail_processor.message_processing_error.catch_all")
          end
        end

        context "when there is no communication channel" do
          it "bounces the message back to the incoming from address" do
            allow(subject).to receive(:get_original_message).with(original_message_id, timestamp).and_return(original_message)

            expect_any_instance_of(Message).not_to receive(:deliver)
            expect(Mailer).to receive(:create_message)

            message = double("incoming message with bad from",
                             incoming_message_attributes.merge(from: ["not_lucy@example.com"],
                                                               reply_to: ["also_not_lucy@example.com"]))
            subject.handle(outgoing_from_address, body, html_body, message, tag)
          end
        end
      end
    end
  end
end
