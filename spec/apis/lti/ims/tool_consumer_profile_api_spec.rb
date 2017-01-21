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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require_dependency "lti/ims/tool_consumer_profile_controller"

module Lti
  module Ims
    describe ToolConsumerProfileController, type: :request do

      describe "GET 'tool_consumer_profile'" do

        let(:account) { Account.create! }

        it 'renders "application/json"' do
          tool_consumer_profile_id = 'a_made_up_id'
          get "/api/lti/accounts/#{account.id}/tool_consumer_profile/#{tool_consumer_profile_id}", tool_consumer_profile_id: tool_consumer_profile_id, account_id: account.id
          expect(response.content_type.to_s).to eq 'application/vnd.ims.lti.v2.toolconsumerprofile+json'
        end

        it 'returns the consumer profile JSON' do
          tool_consumer_profile_id = 'a_made_up_id'
          get "/api/lti/accounts/#{account.id}/tool_consumer_profile/#{tool_consumer_profile_id}", tool_consumer_profile_id: tool_consumer_profile_id, account_id: account.id
          profile = IMS::LTI::Models::ToolConsumerProfile.new.from_json(response.body)
          expect(profile.type).to eq 'ToolConsumerProfile'
        end

        it 'does not include restricted services' do
          restricted_service = "http://www.example.com/api/lti/accounts/#{account.id}/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.OriginalityReport"
          tool_consumer_profile_id = 'a_made_up_id'
          get "/api/lti/accounts/#{account.id}/tool_consumer_profile/#{tool_consumer_profile_id}", tool_consumer_profile_id: tool_consumer_profile_id, account_id: account.id
          profile = IMS::LTI::Models::ToolConsumerProfile.new.from_json(response.body)
          expect(profile.services_offered.to_s).not_to include restricted_service
        end

        it 'does not include restricted capabilities' do
          restricted_cap = "vnd.Canvas.OriginalityReport"

          tool_consumer_profile_id = 'a_made_up_id'
          get "/api/lti/accounts/#{account.id}/tool_consumer_profile/#{tool_consumer_profile_id}", tool_consumer_profile_id: tool_consumer_profile_id, account_id: account.id
          profile = IMS::LTI::Models::ToolConsumerProfile.new.from_json(response.body)

          expect(profile.capability_offered).not_to include restricted_cap
        end
      end

      describe "Get 'tool_consumer_profile' with DeveloperKey" do
        let(:account) { Account.create! }

        before(:each) do
          OAuth::Signature.stubs(:build).returns(mock(verify: true))
          OAuth::Helper.stubs(:parse_header).returns({'oauth_consumer_key' => 'key'})

          dev_key = DeveloperKey.create(api_key: 'test-api-key')

          DeveloperKey.stubs(:find_cached).returns(dev_key)
        end

        it 'shows restricted services if developer credentails are provided' do
          restricted_service = "http://www.example.com/api/lti/accounts/#{account.id}/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.OriginalityReport"

          tool_consumer_profile_id = 'a_made_up_id'
          get "/api/lti/accounts/#{account.id}/tool_consumer_profile/#{tool_consumer_profile_id}", tool_consumer_profile_id: tool_consumer_profile_id, account_id: account.id
          profile = IMS::LTI::Models::ToolConsumerProfile.new.from_json(response.body)

          expect(profile.services_offered.to_s).to include restricted_service
        end

        it 'shows restricted capabilities if developer credentails are provided' do
          restricted_cap = "vnd.Canvas.OriginalityReport.url"

          tool_consumer_profile_id = 'a_made_up_id'
          get "/api/lti/accounts/#{account.id}/tool_consumer_profile/#{tool_consumer_profile_id}", tool_consumer_profile_id: tool_consumer_profile_id, account_id: account.id
          profile = IMS::LTI::Models::ToolConsumerProfile.new.from_json(response.body)

          expect(profile.capability_offered).to include restricted_cap
        end
      end

    end
  end
end
