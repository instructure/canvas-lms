#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe ScopesApiController, type: :request do
  describe "index" do
    before :each do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:api_token_scoping).and_return(true)
    end

    let(:scope_params) { {controller: 'scopes_api', action: 'index', format: 'json', account_id: @account.id.to_s} }

    context "with admin" do
      before :once do
        @account = account_model
        account_admin_user(:account => @account)
        user_with_pseudonym(:user => @admin)
      end

      it "returns expected scopes" do
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/scopes", scope_params)
        expect(json).to match_array TokenScopes::DETAILED_SCOPES.as_json
      end

      it "groups scopes when group_by is passed in" do
        scope_params[:group_by] = "resource"
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/scopes", scope_params)
        expect(json).to match_array TokenScopes::GROUPED_DETAILED_SCOPES.as_json
      end

      it "returns 403 when feature flag is disabled" do
        allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
        api_call(:get, "/api/v1/accounts/#{@account.id}/scopes", scope_params)
        expect(response.code).to eql '403'
      end
    end

    context "with nonadmin" do
      before :once do
        @account = account_model
        user_with_pseudonym(account: @account)
      end

      it "returns a 401" do
        api_call(:get, "/api/v1/accounts/#{@account.id}/scopes", scope_params)
        expect(response.code).to eql '401'
      end
    end
  end
end