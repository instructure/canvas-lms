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
  let(:message_id) { 1 }
  let(:secure_id) { "123abc" }
  let(:shard) do
    stub("shard").tap do |shard|
      shard.stubs(:activate).yields
    end
  end
  let(:user) { stub("user") }
  let(:context) { stub("context", reply_from: "reply-from@example.com") }

  let(:message_attributes) {
    {
        :notification_id => 1,
        :global_id => 2,
        :user => user,
        :context => context,
        :shard => shard,
        :subject => "subject",
        :header => {
            :subject => stub("subject", :charset => "utf8")
        },
        :from => "a@example.com"
    }
  }
  let(:incoming_message) do
    stub("incoming message", message_attributes)
  end
  let(:valid_message) do
    stub("message", message_attributes)
  end
  let(:invalid_user_message) do
    stub("message", message_attributes.merge({user: nil}))
  end
  let(:invalid_context_message) do
    stub("message", message_attributes.merge({context: stub("context")}))
  end

  describe "#route" do
    it "activates the message's shard" do
      message = stub("message",
                     :notification_id => 1,
                     :global_id => 2,
                     :user => user,
                     :context => stub("context", :reply_from => true),
                     :shard => shard
      )
      Message.stubs(:find_by_id).with(message_id).returns(message)
      ReplyToAddress.any_instance.stubs(:secure_id).returns(secure_id)
      shard.expects(:activate)

      subject.handle(outgoing_from_address, body, html_body, incoming_message, message_id, secure_id)
    end

    it "calls reply from on the message's context" do
      Message.stubs(:find_by_id).with(message_id).returns(valid_message)
      ReplyToAddress.any_instance.stubs(:secure_id).returns(secure_id)

      context.expects(:reply_from).with({
                                            :purpose => "general",
                                            :user => user,
                                            :subject => "subject",
                                            :html => html_body,
                                            :text => body
                                        })

      subject.handle(outgoing_from_address, body, html_body, incoming_message, message_id, secure_id)
    end

    context "when a reply from error occurs" do
      let(:incoming_message) { stub("incoming message", :from => ["lucy@example.com"], :subject => "sorry", :header => {:subject => nil}) }

      before do
        Message.stubs(:find_by_id).with(message_id).returns(valid_message)
        ReplyToAddress.any_instance.stubs(:secure_id).returns(secure_id)
        context.stubs(:reply_from).raises(IncomingMail::IncomingMessageProcessor::ReplyFromError)
      end

      context "silent failures" do
        it "silently fails on no message notification id" do
          message = stub("message", :notification_id => nil, :global_id => 2, :context => context)
          Message.stubs(:find_by_id).with(message_id).returns(message)

          Mailer.expects(:create_message).never
          message.context.expects(:reply_from).never

          subject.handle(outgoing_from_address, body, html_body, message, message_id, secure_id)
        end

        it "silenty fails on invalid secure id" do
          message = stub("message", :notification_id => 1, :global_id => 2, :context => context)
          Message.stubs(:find_by_id).with(message_id).returns(message)
          ReplyToAddress.any_instance.stubs(:secure_id).returns("non-matching-secure-id")

          Mailer.expects(:create_message).never
          message.context.expects(:reply_from).never
          subject.handle(outgoing_from_address, body, html_body, incoming_message, message_id, secure_id)
        end

        it "silenty fails if the original message is missing" do
          Message.expects(:find_by_id).with("unknown-message-id").returns(nil)
          Message.any_instance.expects(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, incoming_message, "unknown-message-id", secure_id)
        end
      end

      context "bounced messages" do

        it "bounces the message if user is missing" do
          message = stub("message", :notification_id => 1, :global_id => 2, :user => nil, :context => context, :shard => shard)
          Message.stubs(:find_by_id).with(message_id).returns(message)
          ReplyToAddress.any_instance.stubs(:secure_id).returns(secure_id)

          Message.any_instance.expects(:deliver).never
          Mailer.expects(:create_message)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, message_id, secure_id)
        end

        it "bounces the message on invalid context" do
          Message.stubs(:find_by_id).with(message_id).returns(invalid_context_message)
          ReplyToAddress.any_instance.stubs(:secure_id).returns(secure_id)

          Message.any_instance.expects(:deliver).never
          Mailer.expects(:create_message)

          subject.handle(outgoing_from_address, body, html_body, invalid_context_message, message_id, secure_id)
        end

        it "saves and delivers the message with proper input" do
          user_model
          channel = @user.communication_channels.create!(:path => "lucy@example.com", :path_type => "email")
          channel.confirm!

          shard.expects(:activate).twice.yields

          Message.any_instance.expects(:save)
          Message.any_instance.expects(:deliver)

          subject.handle(outgoing_from_address, body, html_body, incoming_message, message_id, secure_id)
        end

        it "does not send a message if the incoming message has no from" do
          invalid_incoming_message = stub("incoming message", :from => nil, :subject => nil, :header => {:subject => nil})

          Message.any_instance.expects(:deliver).never

          subject.handle(outgoing_from_address, body, html_body, invalid_incoming_message, message_id, secure_id)
        end

        context "with a generic generic_error" do
          it "constructs the message correctly" do
            Message.expects(:find_by_id).with("bad-user-message").returns(invalid_user_message)

            email_subject = "Message Reply Failed: sorry"
            body = <<-BODY.strip_heredoc
            The message titled "sorry" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

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
            message = Message.new(message_attributes)
            Message.expects(:new).with(message_attributes).returns(message)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, "bad-user-message", secure_id)
          end
        end

        context "with a locked discussion topic generic_error" do
          it "constructs the message correctly" do
            context.expects(:reply_from).raises(IncomingMail::IncomingMessageProcessor::ReplyToLockedTopicError.new)

            email_subject = "Message Reply Failed: sorry"
            body = <<-BODY.strip_heredoc
            The message titled "sorry" could not be delivered because the discussion topic is locked. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

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
            message = Message.new(message_attributes)
            Message.expects(:new).with(message_attributes).returns(message)

            subject.handle(outgoing_from_address, body, html_body, incoming_message, message_id, secure_id)
          end
        end

        context "when there is no communication channel" do
          it "bounces the message back to the incoming from address" do
            Message.any_instance.expects(:deliver).never
            Mailer.expects(:create_message)

            subject.handle(outgoing_from_address, body, html_body, valid_message, message_id, secure_id)
          end
        end
      end
    end
  end
end