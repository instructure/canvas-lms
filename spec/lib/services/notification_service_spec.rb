#
# Copyright (C) 2013 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../messages/messages_helper')

module Services
  describe NotificationService do
    context "message delivery" do
      before(:once) do
          user_model
          @au = tie_user_to_account(@user, account: account_model)
          @account.root_account.enable_feature!(:notification_service)
          @message = generate_message(:account_user_notification, :email, @au, user: @user)
          @message.user.account.root_account.enable_feature!(:notification_service)
          @message.save!
          @message.to = "testing123"
          @at = AccessToken.create!(:user => @user, :developer_key => DeveloperKey.default)
      end

      before(:each) do
        @queue = stub('notification queue')
        NotificationService.stubs(:notification_queue).returns(@queue)
      end

      it "processes email message type" do
        @queue.expects(:send_message).once
        @message.path_type = "email"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes twitter message type" do
        @user.user_services.create!(service: 'twitter', service_user_name: 'user', service_user_id: 'user', visible: true)
        @queue.expects(:send_message).once
        @message.path_type = "twitter"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes twilio message type" do
        @queue.expects(:send_message).once
        @message.path_type = "sms"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes sms message type" do
        @queue.expects(:send_message).once
        @message.path_type = "sms"
        @message.to = "+18015550100"
        expect{@message.deliver}.not_to raise_error
      end

      it "expects email sms message type to go through mailer" do
        @queue.expects(:send_message).once
        Mailer.expects(:create_message).once
        @message.path_type = "sms"
        @message.to = "18015550100@vtext.com"
        expect{@message.deliver}.not_to raise_error
      end

      it "expects twilio to not call mailer create_message" do
        @queue.expects(:send_message).once
        Mailer.expects(:create_message).never
        @message.path_type = "sms"
        @message.to = "+18015550100"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes push notification message type" do
        @queue.expects(:send_message).once
        sns_client = mock()
        sns_client.stubs(:create_platform_endpoint).returns(endpoint_arn: 'arn')
        NotificationEndpoint.any_instance.stubs(:sns_client).returns(sns_client)
        @at.notification_endpoints.create!(token: 'token')
        @message.path_type = "push"
        @message.deliver
        expect{@message.deliver}.not_to raise_error
      end

      it "throws error if cannot connect to queue" do
        @queue.stubs(:send_message).raises(Aws::SQS::Errors::ServiceError.new('a', 'b'))
        expect{@message.deliver}.to raise_error(Aws::SQS::Errors::ServiceError)
        expect(@message.transmission_errors).to include("Aws::SQS::Errors::ServiceError")
        expect(@message.workflow_state).to eql("staged")
      end

      it "throws error if queue does not exist" do
        @queue.stubs(:send_message).raises(Aws::SQS::Errors::NonExistentQueue.new('a', 'b'))
        expect{@message.deliver}.to raise_error(Aws::SQS::Errors::NonExistentQueue)
        expect(@message.transmission_errors).to include("Aws::SQS::Errors::NonExistentQueue")
        expect(@message.workflow_state).to eql("staged")
      end

      context 'payload contents' do
        class SendMessageSpy
          attr_accessor :sent_hash
          def send_message(message_body: , queue_url: )
            @sent_hash = JSON.parse(message_body)
          end
        end

        it "sends all parameters (directly)" do
          req_id = SecureRandom.uuid
          RequestContextGenerator.stubs(:request_id).returns(req_id)
          expected = {
            global_id: 1,
            type: 'email',
            message: 'hello',
            target: 'alice@example.com',
            request_id: req_id
          }.with_indifferent_access

          spy = SendMessageSpy.new
          NotificationService.stubs(:notification_queue).returns(spy)

          NotificationService.process(1, 'hello', 'email', 'alice@example.com')
          compare_json(expected, spy.sent_hash)
        end
      end
    end
  end
end
