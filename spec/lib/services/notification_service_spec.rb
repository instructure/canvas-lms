#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_dependency "services/notification_service"

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
        @queue = double('notification queue')
        allow(NotificationService).to receive(:notification_sqs).and_return(@queue)
        allow(NotificationService).to receive(:choose_queue_url).and_return('default')
      end

      it "processes email message type" do
        expect(@queue).to receive(:send_message).once
        @message.path_type = "email"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes twitter message type" do
        @user.user_services.create!(service: 'twitter', service_user_name: 'user', service_user_id: 'user', visible: true)
        expect(@queue).to receive(:send_message).once
        @message.path_type = "twitter"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes twilio message type" do
        expect(@queue).to receive(:send_message).once
        @message.path_type = "sms"
        expect{@message.deliver}.not_to raise_error
      end

      it 'processes slack message type' do
        encrypted_slack_key, salt = Canvas::Security.encrypt_password('testkey'.to_s, 'instructure_slack_encrypted_key')
        @account.settings[:encrypted_slack_key] = encrypted_slack_key
        @account.settings[:encrypted_slack_key_salt] = salt
        expect(@queue).to receive(:send_message).once
        @message.path_type = "slack"
        expect{@message.deliver}.not_to raise_error
      end

      it "processes sms message type" do
        expect(@queue).to receive(:send_message).once
        @message.path_type = "sms"
        @message.to = "+18015550100"
        expect{@message.deliver}.not_to raise_error
      end

      it "expects email sms message type to go through mailer" do
        expect(@queue).to receive(:send_message).once
        expect(Mailer).to receive(:create_message).once
        @message.path_type = "sms"
        @message.to = "18015550100@vtext.com"
        expect{@message.deliver}.not_to raise_error
      end

      it "expects twilio to not call mailer create_message" do
        expect(@queue).to receive(:send_message).once
        expect(Mailer).to receive(:create_message).never
        @message.path_type = "sms"
        @message.to = "+18015550100"
        expect{@message.deliver}.not_to raise_error
      end

      it 'expects slack to not call mailer create_message' do
        encrypted_slack_key, salt = Canvas::Security.encrypt_password('testkey'.to_s, 'instructure_slack_encrypted_key')
        @account.settings[:encrypted_slack_key] = encrypted_slack_key
        @account.settings[:encrypted_slack_key_salt] = salt
        expect(@queue).to receive(:send_message).once
        expect(Mailer).to receive(:create_message).never
        @message.path_type = "slack"
        @message.to = "test@email.com"
        expect{@message.deliver}.not_to raise_error
      end

      it 'expects slack to not enqueue without slack api token' do
        expect(@queue).to receive(:send_message).never
      end

      it "processes push notification message type" do
        expect(@queue).to receive(:send_message).once
        sns_client = double()
        allow(sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: 'arn')
        allow_any_instance_of(NotificationEndpoint).to receive(:sns_client).and_return(sns_client)
        @at.notification_endpoints.create!(token: 'token')
        @message.path_type = "push"
        @message.deliver
        expect{@message.deliver}.not_to raise_error
      end

      it "throws error if cannot connect to queue" do
        allow(@queue).to receive(:send_message).and_raise(Aws::SQS::Errors::ServiceError.new('a', 'b'))
        expect{@message.deliver}.to raise_error(Aws::SQS::Errors::ServiceError)
        expect(@message.transmission_errors).to include("Aws::SQS::Errors::ServiceError")
        expect(@message.workflow_state).to eql("staged")
      end

      it "throws error if queue does not exist" do
        allow(@queue).to receive(:send_message).and_raise(Aws::SQS::Errors::NonExistentQueue.new('a', 'b'))
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
          allow(RequestContextGenerator).to receive(:request_id).and_return(req_id)
          expected = {
            global_id: 1,
            type: 'email',
            message: 'hello',
            target: 'alice@example.com',
            request_id: req_id
          }.with_indifferent_access

          spy = SendMessageSpy.new
          allow(NotificationService).to receive(:notification_sqs).and_return(spy)

          NotificationService.process(1, 'hello', 'email', 'alice@example.com')
          expect(expected).to eq spy.sent_hash
        end
      end
    end
  end
end
