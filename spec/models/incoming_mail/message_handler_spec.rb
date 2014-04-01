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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe IncomingMail::MessageHandler do
  let(:outgoing_from_address) { "no-reply@example.com" }
  let(:body) { "Hello" }
  let(:html_body) { "Hello" }
  let(:original_message_id) { 1 }
  let(:secure_id) { "123abc" }
  let(:tag) { "#{secure_id}-#{original_message_id}" }
    let(:shard) do
    stub("shard").tap do |shard|
      shard.stubs(:activate).yields
    end
  end
  let(:user) { stub("user") }
  let(:context) { stub("context", reply_from: "reply-from@example.com") }

  let(:original_message_attributes) {
    {
        :notification_id => 1,
        :shard => shard,
        :context => context,
        :user => user,
    }
  }

  let(:incoming_message_attributes) {
    {
        subject: "some subject",
        header: {
            :subject => stub("subject", :charset => "utf8")
        },
        from: ["lucy@example.com"]
    }
  }

  let(:incoming_message) { stub("incoming message", incoming_message_attributes) }
  let(:original_message) { stub("original message", original_message_attributes) }

  before do
    IncomingMail::ReplyToAddress.any_instance.stubs(:secure_id).returns(secure_id)
  end

  describe "#route" do
    it "activates the message's shard" do
      Message.stubs(:find_by_id).with(original_message_id).returns(original_message)
      shard.expects(:activate)

      subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
    end

    it "calls reply from on the message's context" do
      context.expects(:reply_from)

      Message.stubs(:find_by_id).with(original_message_id).returns(original_message)

      subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
    end

    context "when a reply from error occurs" do
      context "silent failures" do
        it "silently fails on no message notification id" do
          message = stub("original message without notification id", original_message_attributes.merge(:notification_id => nil))
          Message.stubs(:find_by_id).with(original_message_id).returns(message)

          Mailer.expects(:create_message).never
          message.context.expects(:reply_from).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "silenty fails on invalid secure id" do
          IncomingMail::ReplyToAddress.any_instance.stubs(:secure_id).returns("deadbeef") # non-matching secure-id

          Mailer.expects(:create_message).never
          original_message.context.expects(:reply_from).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "silenty fails if the original message is missing" do
          Message.expects(:find_by_id).with(42).returns(nil)
          Message.any_instance.expects(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, "#{secure_id}-42")
        end
      end

      context "bounced messages" do
        it "bounces the message if user is missing" do
          message = stub("original message without user", original_message_attributes.merge(:user => nil))
          Message.stubs(:find_by_id).with(original_message_id).returns(message)

          Message.any_instance.expects(:deliver).never
          Mailer.expects(:create_message)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "bounces the message on invalid context" do
          message = stub("original message with invalid context", original_message_attributes.merge({context: stub("context")}))
          Message.stubs(:find_by_id).with(original_message_id).returns(message)

          Message.any_instance.expects(:deliver).never
          Mailer.expects(:create_message)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "saves and delivers the message with proper input" do
          user_model
          channel = @user.communication_channels.create!(:path => "lucy@example.com", :path_type => "email")
          channel.confirm!
          message = stub("original message with invalid context", original_message_attributes.merge({context: stub("context")}))
          Message.stubs(:find_by_id).with(original_message_id).returns(message)

          Message.any_instance.expects(:save)
          Message.any_instance.expects(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
        end

        it "does not send a message if the incoming message has no from" do
          invalid_incoming_message = stub("invalid incoming message", incoming_message_attributes.merge(from: nil))
          Message.stubs(:find_by_id).with(original_message_id).returns(original_message)

          Message.any_instance.expects(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, invalid_incoming_message, tag)
        end

        context "with a generic generic_error" do
          it "constructs the message correctly" do
            message = stub("original message without user", original_message_attributes.merge(:user => nil))
            Message.stubs(:find_by_id).with(original_message_id).returns(message)

            email_subject = "Message Reply Failed: some subject"
            body = <<-BODY.strip_heredoc
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
            Message.expects(:new).with(message_attributes).returns(expected_bounce_message)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "with a locked discussion topic generic_error" do
          it "constructs the message correctly" do
            Message.stubs(:find_by_id).with(original_message_id).returns(original_message)
            context.expects(:reply_from).raises(IncomingMail::ReplyToLockedTopicError.new)

            email_subject = "Message Reply Failed: some subject"
            body = <<-BODY.strip_heredoc
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
            Message.expects(:new).with(message_attributes).returns(expected_bounce_message)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "with a generic reply to error" do
          it "constructs the message correctly" do
            Message.stubs(:find_by_id).with(original_message_id).returns(original_message)
            context.expects(:reply_from).raises(IncomingMail::UnknownAddressError.new)

            email_subject = "Message Reply Failed: some subject"
            body = <<-BODY.strip_heredoc
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
            Message.expects(:new).with(message_attributes).returns(expected_bounce_message)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end

        context "when there is no communication channel" do
          it "bounces the message back to the incoming from address" do
            Message.stubs(:find_by_id).with(original_message_id).returns(original_message)
            context.expects(:reply_from).raises(IncomingMail::ReplyToLockedTopicError.new)

            Message.any_instance.expects(:deliver).never
            Mailer.expects(:create_message)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, tag)
          end
        end
      end
    end
  end
end
