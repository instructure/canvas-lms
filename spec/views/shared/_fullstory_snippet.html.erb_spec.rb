# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "shared/_fullstory_snippet" do
  before do
    @context = {}
    @current_user = User.new
    @domain_root_account = Account.default
    assign(:context, @context)
    assign(:current_user, @current_user)
    assign(:domain_root_account, @domain_root_account)
    allow(view).to receive(:fullstory_app_key).and_return("fak")
  end

  it "renders" do
    render partial: "shared/fullstory_snippet", locals: {}
    expect(response).not_to be_nil
  end

  describe "with fullstory enabled" do
    before do
      allow(@current_user).to receive_messages(global_id: 1, id: 1)
      allow(@domain_root_account).to receive(:settings).and_return({ enable_fullstory: true })
    end

    it "includes the homeroom variable when set" do
      render partial: "shared/fullstory_snippet", locals: {}
      expect(response.body).to include("feature_homeroom_course_bool")
    end

    it "sets the k5_user variable when set" do
      render partial: "shared/fullstory_snippet", locals: {}
      expect(response.body).to include("k5_user_bool")
    end

    it "sets org_type when available" do
      @current_user.account.external_integration_keys.create!(key_type: "salesforce_org_type", key_value: "Higher Ed")
      render partial: "shared/fullstory_snippet", locals: {}
      expect(response.body).to include("org_type_str: 'Higher Ed'")
    end
  end
end
