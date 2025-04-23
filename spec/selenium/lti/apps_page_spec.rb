# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../common"

describe "Apps Page" do
  let_once(:account) { account_model }
  let_once(:user) { account_admin_user(account:) }

  include_context "in-process server selenium tests"

  before(:once) do
    account.enable_feature!(:lti_registrations_page)
  end

  before do
    user_session(user)
  end

  it "dynamically sets breadcrumbs" do
    get("/accounts/#{account.id}/apps/manage")

    wait_for_ajaximations
    expect(f("#breadcrumbs")).to include_text("Apps - Manage")
  end

  context "with the discover page enabled" do
    before(:once) do
      account.enable_feature!(:lti_registrations_discover_page)
    end

    it "dynamically changes breadcrumbs" do
      get("/accounts/#{account.id}/apps")
      wait_for_ajaximations

      expect(f("#breadcrumbs")).to include_text("Apps - Discover")

      f("#tab-manage > span").click

      wait_for_ajaximations
      expect(f("#breadcrumbs")).to include_text("Apps - Manage")
    end
  end

  context "with the monitor page enabled" do
    before(:once) do
      account.enable_feature!(:lti_registrations_usage_data)
    end

    it "dynamically sets breadcrumbs for monitor page" do
      get("/accounts/#{account.id}/apps/monitor")
      wait_for_ajaximations

      expect(f("#breadcrumbs")).to include_text("Apps - Monitor")

      f("#tab-manage > span").click
      wait_for_ajaximations
      expect(f("#breadcrumbs")).to include_text("Apps - Manage")
    end
  end
end
