#
# Copyright (C) 2015 - present Instructure, Inc.
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

  before do
    @sns_client = double()
    allow(DeveloperKey).to receive(:sns).and_return(@sns_client)
  end

  describe "after_create" do
    it "creates an sns endpoint" do
      expect(@sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: 'arn')
      ne = @at.notification_endpoints.create!(token: 'token')
      expect(ne.arn).to eq 'arn'
    end

    it "resets the user data on an existing, conflicting sns endpoint" do
      # i.e. it steals ownership of the sns endpoint from other NotificationEndpoints
      expect(@sns_client).to receive(:create_platform_endpoint).and_raise(Aws::SNS::Errors::InvalidParameter.new(nil, "Invalid parameter: Token Reason: Endpoint existing_arn already exists with the same Token, but different attributes."))
      expect(@sns_client).to receive(:set_endpoint_attributes).with(endpoint_arn: 'existing_arn', attributes: {'CustomUserData' => @at.global_id.to_s})
      ne = @at.notification_endpoints.create!(token: 'token')
      expect(ne.arn).to eq 'existing_arn'
    end
  end

  describe "#push_json" do
    it "returns false when the endpoint is disabled" do
      expect(@sns_client).to receive(:get_endpoint_attributes).and_return(double(attributes: {'Enabled' => 'false', 'CustomUserData' => @at.global_id.to_s}))
      ne = @at.notification_endpoints.new(token: 'token')
      expect(ne.push_json('json')).to be_falsey
    end

    it "returns false when the endpoint isn't owned" do
      expect(@sns_client).to receive(:get_endpoint_attributes).and_return(double(attributes: {'Enabled' => 'true', 'CustomUserData' => 'not my id'}))
      ne = @at.notification_endpoints.new(token: 'token')
      expect(ne.push_json('json')).to be_falsey
    end

    it "returns false if the token has changed" do
      expect(@sns_client).to receive(:get_endpoint_attributes).and_return(double(attributes: {'Enabled' => 'true', 'CustomUserData' => @at.global_id.to_s, 'Token' => 'token2'}))
      ne = @at.notification_endpoints.new(token: 'token')
      expect(ne.push_json('json')).to be_falsey
    end
  end

  describe "#destroy" do
    it "deletes the endpoint" do
      allow(@sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: 'arn')
      ne = @at.notification_endpoints.create!(token: 'token')

      expect(@sns_client).to receive(:get_endpoint_attributes).and_return(double(attributes: {'Enabled' => 'true', 'CustomUserData' => @at.global_id.to_s}))
      expect(@sns_client).to receive(:delete_endpoint)
      ne.destroy
    end

    it "doesn't delete endpoints it doesn't own" do
      allow(@sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: 'arn')
      ne = @at.notification_endpoints.create!(token: 'token')

      expect(@sns_client).to receive(:get_endpoint_attributes).and_return(double(attributes: {'Enabled' => 'true', 'CustomUserData' => 'not my id'}))
      expect(@sns_client).to receive(:delete_endpoint).never
      ne.destroy
    end
  end

  it "should be soft-deleteable" do
    allow(@sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: 'arn')
    ne = @at.notification_endpoints.create!(token: 'token')

    allow(ne).to receive(:endpoint_exists?).and_return(false)
    ne.destroy
    expect(ne.reload.workflow_state).to eq "deleted"
    expect(@user.notification_endpoints.count).to eq 0

    ne2 = @at.notification_endpoints.create!(token: 'token')
    AccessToken.where(:id => @at).update_all(:workflow_state => 'deleted')
    expect(@user.notification_endpoints.count).to eq 0
  end
end
