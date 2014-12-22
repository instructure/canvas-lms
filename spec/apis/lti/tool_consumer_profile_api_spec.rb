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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

module Lti
  describe ToolConsumerProfileController, type: :request  do

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

    end

  end
end