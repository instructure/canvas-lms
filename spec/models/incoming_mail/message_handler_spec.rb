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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe IncomingMail::MessageHandler do
  specs_require_sharding

  let(:outgoing_from_address) { "no-reply@example.com" }
  let(:body) { "Hello" }
  let(:html_body) { "Hello" }
  let(:original_message_id) { Shard.short_id_for(@shard1.global_id_for(42)) }
  let(:secure_id) { "123abc" }
  let(:tag) { "#{secure_id}-#{original_message_id}" }
  let(:shard) do
    shard = double("shard")
    allow(shard).to receive(:activate).and_yield
    shard
  end
  let_once(:user) do
    user_model
    channel = @user.communication_channels.create!(:path => "lucy@example.com", :path_type => "email")
    channel.confirm!
    @user
  end
  let(:context) { double("context", reply_from: nil) }

  let(:original_message_attributes) {
    {
        :notification_id => 1,
        :shard => shard,
        :context => context,
        :user => user,
        :global_id => 1,
        :to => "lucy@example.com"
    }
  }

  let(:incoming_message_attributes) {
    {
        subject: "some subject",
        header: {
            :subject => double("subject", :charset => "utf8")
        },
        from: ["lucy@example.com"],
        reply_to: ["lucy@example.com"],
        message_id: 1,
    }
  }

  let(:incoming_message) { double("incoming message", incoming_message_attributes) }
  let(:original_message) { double("original message", original_message_attributes) }

  before do
    allow(Canvas::Security).to receive(:verify_hmac_sha1).and_return(true)
  end

  describe "#route" do
    it "activates the message's shard" do
      enable_cache do
        allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
        expect(shard).to receive(:activate)

        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
      end
    end

    it "calls reply from on the message's context" do
      enable_cache do
        expect(context).to receive(:reply_from)
        allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
      end
    end

    it "is idempotent (via caching)" do
      enable_cache do
        expect(context).to receive(:reply_from).once
        allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
      end
    end

    context "when a reply from error occurs" do
      context "silent failures" do
        it "silently fails on no message notification id" do
          message = double("original message without notification id", original_message_attributes.merge(:notification_id => nil))
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: message))
          expect(Mailer).to receive(:create_message).never
          expect(message.context).to receive(:reply_from).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "silently fails on invalid secure id" do
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
          allow(Canvas::Security).to receive(:verify_hmac_sha1).and_return(false)
          expect(Mailer).to receive(:create_message).never
          expect(original_message.context).to receive(:reply_from).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "silently fails if the original message is missing" do
          expect(Message).to receive(:where).with(id: original_message_id).and_return(double(first: nil))
          expect_any_instance_of(Message).to receive(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, "#{secure_id}-#{original_message_id}")
        end

        it "silently fails if the address tag is invalid" do
          expect(Message).to receive(:where).never
          expect_any_instance_of(Message).to receive(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, "#{secure_id}-not-an-id")
        end

        it "silently fails if the message is not from one of the original recipient's email addresses" do
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
          expect_any_instance_of(Message).to receive(:deliver).never
          expect(Account.site_admin).to receive(:feature_enabled?).with(:notification_service).and_return(false)
          expect(original_message.context).to receive(:reply_from).never
          message = double("incoming message with bad from",
                           incoming_message_attributes.merge(:from => ['not_lucy@example.com'],
                                                             :reply_to => ['also_not_lucy@example.com']))
          subject.handle(outgoing_from_address, body, html_body, message, tag)
        end
      end

      context "bounced messages" do
        it "bounces if user is missing" do
          message = double("original message without user", original_message_attributes.merge(:user => nil))
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: message))
          expect_any_instance_of(Message).to receive(:deliver)
          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "bounces the message on invalid context" do
          message = double("original message with invalid context", original_message_attributes.merge({context: double("context")}))
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: message))
          expect_any_instance_of(Message).to receive(:save)
          expect_any_instance_of(Message).to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "saves and delivers the message with proper input" do
          message = double("original message with invalid context", original_message_attributes.merge({context: double("context")}))
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: message))
          expect_any_instance_of(Message).to receive(:save)
          expect_any_instance_of(Message).to receive(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "does not send a message if the incoming message has no from" do
          invalid_incoming_message = double("invalid incoming message", incoming_message_attributes.merge(from: nil, reply_to: nil))
          allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
          expect_any_instance_of(Message).to receive(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, invalid_incoming_message, tag)
        end

        context "with a generic generic_error" do
          it "constructs the message correctly" do
            message = double("original message without user", original_message_attributes.merge(:context => nil))
            allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: message))

            email_subject = "Undelivered message"
            body = <<-BODY.strip_heredoc.strip
            The message titled "some subject" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

            Thank you,
            Canvas Support
            BODY

            message_attributes = {
                :to => "lucy@example.com",
                :from => "no-reply@example.com",
                :subject => email_subject,
                :body => body,
                :delay_for => 0,
                :context => nil,
                :path_type => "email",
                :from_name => "Instructure",
            }
            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "with a locked discussion topic generic_error" do
          it "constructs the message correctly" do
            allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
            expect(context).to receive(:reply_from).and_raise(IncomingMail::Errors::ReplyToLockedTopic.new)

            email_subject = "Undelivered message"
            body = <<-BODY.strip_heredoc.strip
            The message titled "some subject" could not be delivered because the discussion topic is locked. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

            Thank you,
            Canvas Support
            BODY

            message_attributes = {
                :to => "lucy@example.com",
                :from => "no-reply@example.com",
                :subject => email_subject,
                :body => body,
                :delay_for => 0,
                :context => nil,
                :path_type => "email",
                :from_name => "Instructure",
            }
            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "with a generic reply to error" do
          it "constructs the message correctly" do
            allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))
            expect(context).to receive(:reply_from).and_raise(IncomingMail::Errors::UnknownAddress.new)

            email_subject = "Undelivered message"
            body = <<-BODY.strip_heredoc.strip
            The message titled "some subject" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

            Thank you,
            Canvas Support
            BODY

            message_attributes = {
                :to => "lucy@example.com",
                :from => "no-reply@example.com",
                :subject => email_subject,
                :body => body,
                :delay_for => 0,
                :context => nil,
                :path_type => "email",
                :from_name => "Instructure",
            }
            expected_bounce_message = Message.new(message_attributes)
            expect(Message).to receive(:new).with(message_attributes).and_return(expected_bounce_message)
            expect(expected_bounce_message).to receive(:deliver)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "when there is no communication channel" do
          it "bounces the message back to the incoming from address" do
            allow(Message).to receive(:where).with(id: original_message_id).and_return(double(first: original_message))

            expect_any_instance_of(Message).to receive(:deliver).never
            expect(Mailer).to receive(:create_message)

            message = double("incoming message with bad from",
                           incoming_message_attributes.merge(:from => ['not_lucy@example.com'],
                                                             :reply_to => ['also_not_lucy@example.com']))
            subject.handle(outgoing_from_address, body, html_body, message, tag)
          end
        end
      end
    end
  end
end
