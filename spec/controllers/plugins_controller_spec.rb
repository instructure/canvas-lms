# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe PluginsController do
  include Rails.application.routes.url_helpers

  describe "#update" do
    it "still enables plugins even with no settings posted" do
      expect(PluginSetting.find_by(name: "account_reports")).to be_nil
      allow(controller).to receive(:require_setting_site_admin).and_return(true)

      put "update", params: { id: "account_reports", account_id: Account.default.id, plugin_setting: { disabled: false } }
      expect(response).to be_redirect
      ps = PluginSetting.find_by!(name: "account_reports")
      expect(ps).to be_enabled
    end

    it "trims posted params" do
      ps = PluginSetting.new(name: "big_blue_button")
      ps.settings = {}.with_indifferent_access
      ps.disabled = false
      ps.save!

      allow(controller).to receive(:require_setting_site_admin).and_return(true)
      # The 'all' parameter is necessary for this test to pass when the
      # multiple root accounts plugin is installed
      put "update", params: { id: "big_blue_button", settings: { domain: " abc ", secret: "secret", recording_enabled: "0", free_trial: true, send_avatar: true, replace_with_alternatives: false, use_fallback: false }, all: 1 }
      expect(response).to be_redirect
      ps.reload
      expect(ps.settings[:domain]).to eq "abc"
    end

    context "account_reports" do
      it "can disable reports" do
        ps = PluginSetting.new(name: "account_reports")
        ps.settings = { course_storage_csv: true }.with_indifferent_access
        ps.save!

        allow(controller).to receive(:require_setting_site_admin).and_return(true)
        # The 'all' parameter is necessary for this test to pass when the
        # multiple root acoounts plugin is installed
        put "update", params: { id: "account_reports", settings: { "course_storage_csv" => "0" }, all: 1 }
        expect(response).to be_redirect
        ps.reload
        expect(ps.settings[:course_storage_csv]).to be false
      end
    end
  end
end
