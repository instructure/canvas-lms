#
# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe NotificationEndpoint do
  before :once do
    @at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
  end

  describe "after_create" do
    it "creates an sns endpoint" do
      sns_client = mock()
      sns_client.expects(:create_platform_endpoint).returns(endpoint_arn: 'arn')
      NotificationEndpoint.any_instance.expects(:sns_client).returns(sns_client)
      ne = @at.notification_endpoints.create!(token: 'token')
      expect(ne.arn).to eq 'arn'
    end

    it "resets the user data on an existing, conflicting sns endpoint" do
      # i.e. it steals ownership of the sns endpoint from other NotificationEndpoints
      sns_client = mock()
      sns_client.expects(:create_platform_endpoint).raises(AWS::SNS::Errors::InvalidParameter, "Invalid parameter: Token Reason: Endpoint existing_arn already exists with the same Token, but different attributes.")
      sns_client.expects(:set_endpoint_attributes).with(endpoint_arn: 'existing_arn', attributes: {'CustomUserData' => @at.global_id.to_s})
      NotificationEndpoint.any_instance.expects(:sns_client).twice.returns(sns_client)
      ne = @at.notification_endpoints.create!(token: 'token')
      expect(ne.arn).to eq 'existing_arn'
    end
  end

  describe "#push_json" do
    it "returns false when the endpoint is disabled" do
      sns_client = mock()
      sns_client.expects(:get_endpoint_attributes).returns(attributes: {'Enabled' => 'false', 'CustomUserData' => @at.global_id.to_s})
      NotificationEndpoint.any_instance.expects(:sns_client).returns(sns_client)
      ne = @at.notification_endpoints.new(token: 'token')
      expect(ne.push_json('json')).to be_falsey
    end

    it "returns false when the endpoint isn't owned" do
      sns_client = mock()
      sns_client.expects(:get_endpoint_attributes).returns(attributes: {'Enabled' => 'true', 'CustomUserData' => 'not my id'})
      NotificationEndpoint.any_instance.expects(:sns_client).returns(sns_client)
      ne = @at.notification_endpoints.new(token: 'token')
      expect(ne.push_json('json')).to be_falsey
    end
  end

  describe "#destroy" do
    it "deletes the endpoint" do
      ne = @at.notification_endpoints.build(token: 'token', arn: 'arn')
      expect(ne.save_without_callbacks).to be_truthy

      sns_client = mock()
      sns_client.expects(:get_endpoint_attributes).returns(attributes: {'Enabled' => 'true', 'CustomUserData' => @at.global_id.to_s})
      sns_client.expects(:delete_endpoint)
      NotificationEndpoint.any_instance.expects(:sns_client).twice.returns(sns_client)
      ne.destroy
    end

    it "doesn't delete endpoints it doesn't own" do
      ne = @at.notification_endpoints.build(token: 'token', arn: 'arn')
      expect(ne.save_without_callbacks).to be_truthy

      sns_client = mock()
      sns_client.expects(:get_endpoint_attributes).returns(attributes: {'Enabled' => 'true', 'CustomUserData' => 'not my id'})
      sns_client.expects(:delete_endpoint).never
      NotificationEndpoint.any_instance.expects(:sns_client).returns(sns_client)
      ne.destroy
    end
  end
end
