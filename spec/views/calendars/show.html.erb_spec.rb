# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe "calendars/show" do
  before do
    @domain_root_account = Account.default
    @sub_account = @domain_root_account.sub_accounts.create!(name: "sub-account")
    @domain_root_account.allow_feature!(:discussion_checkpoints)
    @domain_root_account.disable_feature!(:discussion_checkpoints)
    @sub_account.disable_feature!(:discussion_checkpoints)
    @current_user = User.create!
    @contexts_json = []
    @manage_contexts = []
    @selected_contexts = []
    @active_event_id = nil
    @view_start = Time.zone.now
    @feed_url = "feed_url"
    assign(:domain_root_account, @domain_root_account)
    assign(:contexts_json, @contexts_json)
    assign(:manage_contexts, @manage_contexts)
    assign(:selected_contexts, @selected_contexts)
    assign(:active_event_id, @active_event_id)
    assign(:view_start, @view_start)
    assign(:feed_url, @feed_url)
    assign(:current_user, @current_user)
  end

  context "js_env.SHOW_CHECKPOINTS" do
    it "sets to true when discussion checkponts FF is enabled in the sub-account" do
      @sub_account.enable_feature!(:discussion_checkpoints)
      render

      expect(controller.js_env[:CALENDAR][:SHOW_CHECKPOINTS]).to be true
    end

    it "sets to true when discussion checkpoints FF is enabled in the root account" do
      @domain_root_account.enable_feature!(:discussion_checkpoints)
      render

      expect(controller.js_env[:CALENDAR][:SHOW_CHECKPOINTS]).to be true
    end

    it "sets to false when discussion checkpoints FF is not enabled neither in the root account nor the sub-account" do
      render

      expect(controller.js_env[:CALENDAR][:SHOW_CHECKPOINTS]).to be false
    end
  end
end
