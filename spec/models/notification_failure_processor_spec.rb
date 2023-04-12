# frozen_string_literal: true

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

require_relative "../messages/messages_helper"

describe NotificationFailureProcessor do
  before(:once) do
    user_model
    @au = tie_user_to_account(@user, account: account_model)
  end

  def mock_failure_summary(obj)
    failure_summary = double
    allow(failure_summary).to receive(:body).and_return(obj.to_json)
    failure_summary
  end

  def mock_queue(bare_failure_summaries)
    queue = double
    expect(queue).to receive(:before_request)
    expectation = expect(queue).to receive(:poll)
    bare_failure_summaries.each do |s|
      expectation = expectation.and_yield(mock_failure_summary(s))
    end
    queue
  end

  describe ".process" do
    it "puts multiple messages into error state" do
      messages = [
        generate_message(:account_user_notification, :email, @au, user: @user),
        generate_message(:account_user_notification, :sms, @au, user: @user)
      ]
      messages.each(&:save!) # generate a message id

      failure_queue = mock_queue([
                                   {
                                     global_id: messages[0].notification_service_id,
                                     error_context: nil,
                                     error: "Error from mail system"
                                   },
                                   {
                                     global_id: messages[1].notification_service_id,
                                     error_context: nil,
                                     error: "Error from SNS system"
                                   }
                                 ])
      nfp = NotificationFailureProcessor.new
      allow(NotificationFailureProcessor).to receive(:config).and_return({
                                                                           access_key: "key",
                                                                           secret_access_key: "secret"
                                                                         })
      allow(nfp).to receive(:notification_failure_queue).and_return(failure_queue)
      nfp.process

      messages.each do |msg|
        msg.reload
        expect(msg.state).to eq(:transmission_error)
        expect(msg.transmission_errors).not_to be_blank
      end
    end

    it "deletes disabled push notification endpoints" do
      good_arn = "good arn"
      bad_arn = "bad arn"

      @at = AccessToken.create!(user: @user, developer_key: DeveloperKey.default)

      sns_client = double
      expect(sns_client).to receive(:get_endpoint_attributes).at_least(:once).and_return(double(attributes: { "Enabled" => "true", "CustomUserData" => @at.global_id.to_s }))
      expect(sns_client).to receive(:create_platform_endpoint).twice.and_return({ endpoint_arn: bad_arn }, { endpoint_arn: good_arn })
      bad_ne = @at.notification_endpoints.new(token: "token1") # order matters
      good_ne = @at.notification_endpoints.new(token: "token2")
      allow(bad_ne).to receive(:sns_client).and_return(sns_client)
      allow(good_ne).to receive(:sns_client).and_return(sns_client)
      bad_ne.save!
      good_ne.save!
      allow_any_instantiation_of(bad_ne).to receive(:sns_client).and_return(sns_client)
      allow_any_instantiation_of(good_ne).to receive(:sns_client).and_return(sns_client)

      @message = generate_message(:account_user_notification, :push, @au, user: @user)
      @message.save! # generate a message id

      failure_queue = mock_queue([
                                   {
                                     global_id: @message.notification_service_id,
                                     error_context: bad_arn,
                                     error: "EndpointDisabled: Endpoint is disabled"
                                   },
                                 ])
      nfp = NotificationFailureProcessor.new
      allow(NotificationFailureProcessor).to receive(:config).and_return({
                                                                           access_key: "key",
                                                                           secret_access_key: "secret"
                                                                         })
      allow(nfp).to receive(:notification_failure_queue).and_return(failure_queue)

      expect(sns_client).to receive(:delete_endpoint).with(endpoint_arn: bad_arn)
      nfp.process
      expect(NotificationEndpoint.active.where(arn: good_arn)).not_to be_empty
      expect(NotificationEndpoint.active.where(arn: bad_arn)).to be_empty
      expect(NotificationEndpoint.where(arn: bad_arn).first).to be_deleted
    end

    it "fails silently when given an invalid message id" do
      nonexistent_id = 123_456_789

      failure_queue = mock_queue([
                                   {
                                     global_id: nonexistent_id,
                                     error_context: nil,
                                     error: "error"
                                   },
                                 ])
      nfp = NotificationFailureProcessor.new
      allow(NotificationFailureProcessor).to receive(:config).and_return({
                                                                           access_key: "key",
                                                                           secret_access_key: "secret"
                                                                         })
      allow(nfp).to receive(:notification_failure_queue).and_return(failure_queue)

      expect { Message.find(nonexistent_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { nfp.process }.not_to raise_error
    end

    it "breaks out early when exceeding its timeline" do
      nfp = NotificationFailureProcessor.new
      allow(NotificationFailureProcessor).to receive(:config).and_return({
                                                                           access_key: "key",
                                                                           secret_access_key: "secret"
                                                                         })
      queue = double
      before_request = nil
      expect(queue).to receive(:before_request) do |&block|
        before_request = block
      end
      reached = false
      expect(queue).to receive(:poll) do
        before_request.call
        reached = true
        Timecop.travel(10.minutes.from_now)
        before_request.call
        raise "not reached"
      end
      allow(nfp).to receive(:notification_failure_queue).and_return(queue)

      Timecop.freeze do
        expect { nfp.process }.to throw_symbol(:stop_polling)
      end
      expect(reached).to be true
    end

    context "shards" do
      specs_require_sharding

      it "finds the message on another shard" do
        message = generate_message(:account_user_notification, :email, @au, user: @user)
        message.save!
        failure_queue = mock_queue([
                                     {
                                       global_id: message.notification_service_id,
                                       error_context: nil,
                                       error: "Error from mail system"
                                     }
                                   ])
        nfp = NotificationFailureProcessor.new
        allow(NotificationFailureProcessor).to receive(:config).and_return({
                                                                             access_key: "key",
                                                                             secret_access_key: "secret"
                                                                           })
        allow(nfp).to receive(:notification_failure_queue).and_return(failure_queue)
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
