#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../messages/messages_helper')

describe NotificationFailureProcessor do
  before(:once) do
    user_model
    @au = tie_user_to_account(@user, account: account_model)
  end

  def mock_failure_summary(obj)
    failure_summary = mock
    failure_summary.stubs(:body).returns(obj.to_json)
    failure_summary
  end

  def mock_queue(bare_failure_summaries)
    queue = mock
    queue.expects(:poll).multiple_yields(*bare_failure_summaries.map { |s| mock_failure_summary(s) })
    queue
  end

  describe '.process' do
    it "puts multiple messages into error state" do
      messages = [
        generate_message(:account_user_notification, :email, @au, user: @user),
        generate_message(:account_user_notification, :sms, @au, user: @user)
      ]
      messages.each(&:save!) # generate a message id

      failure_queue = mock_queue([
        {
          global_id: messages[0].id,
          error_context: nil,
          error: 'Error from mail system'
        },
        {
          global_id: messages[1].id,
          error_context: nil,
          error: 'Error from SNS system'
        }
      ])
      nfp = NotificationFailureProcessor.new(access_key: 'key', secret_access_key: 'secret')
      nfp.stubs(:notification_failure_queue).returns(failure_queue)
      nfp.process

      messages.each do |msg|
        msg.reload
        expect(msg.state).to eq(:transmission_error)
        expect(msg.transmission_errors).not_to be_blank
      end
    end

    it "deletes disabled push notification endpoints" do
      good_arn = 'good arn'
      bad_arn = 'bad arn'

      @at = AccessToken.create!(:user => @user, :developer_key => DeveloperKey.default)

      sns_client = mock()
      NotificationEndpoint.any_instance.expects(:sns_client).at_least_once.returns(sns_client)
      sns_client.expects(:get_endpoint_attributes).at_least_once.returns(attributes: {'Enabled' => 'true', 'CustomUserData' => @at.global_id.to_s})
      sns_client.expects(:create_platform_endpoint).twice.returns({endpoint_arn: bad_arn}, {endpoint_arn: good_arn})
      bad_ne = @at.notification_endpoints.create!(token: 'token1') # order matters
      good_ne = @at.notification_endpoints.create!(token: 'token2')

      @message = generate_message(:account_user_notification, :push, @au, user: @user)
      @message.save! # generate a message id

      failure_queue = mock_queue([
        {
          global_id: @message.id,
          error_context: bad_arn,
          error: 'EndpointDisabled: Endpoint is disabled'
        },
      ])
      nfp = NotificationFailureProcessor.new(access_key: 'key', secret_access_key: 'secret')
      nfp.stubs(:notification_failure_queue).returns(failure_queue)

      sns_client.expects(:delete_endpoint).with(endpoint_arn: bad_arn)
      nfp.process
      expect(NotificationEndpoint.where(arn: good_arn)).not_to be_empty
      expect(NotificationEndpoint.where(arn: bad_arn)).to be_empty
    end

    it "fails silently when given an invalid message id" do
      nonexistent_id = 123456789

      failure_queue = mock_queue([
        {
          global_id: nonexistent_id,
          error_context: nil,
          error: 'error'
        },
      ])
      nfp = NotificationFailureProcessor.new(access_key: 'key', secret_access_key: 'secret')
      nfp.stubs(:notification_failure_queue).returns(failure_queue)

      expect{ Message.find(nonexistent_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect{ nfp.process }.not_to raise_error
    end

    context 'shards' do
      specs_require_sharding

      it 'should find the message on another shard' do
        message = generate_message(:account_user_notification, :email, @au, user: @user)
        message.save!
        failure_queue = mock_queue([
          {
            global_id: message.global_id,
            error_context: nil,
            error: 'Error from mail system'
          }
        ])
        nfp = NotificationFailureProcessor.new(access_key: 'key', secret_access_key: 'secret')
        nfp.stubs(:notification_failure_queue).returns(failure_queue)
        @shard1.activate do
          nfp.process
        end

        message.reload
        expect(message.state).to eq(:transmission_error)
        expect(message.transmission_errors).not_to be_blank
      end
    end
  end
end
