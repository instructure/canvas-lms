#
# Copyright (C) 2011 Instructure, Inc.
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

require_relative '../spec_helper'

describe PluginsController do
  include Rails.application.routes.url_helpers

  describe "#update" do
    it "still enables plugins even with no settings posted" do
      expect(PluginSetting.find_by(name: 'error_reporting')).to be_nil
      controller.stubs(:require_setting_site_admin).returns(true)

      put 'update', id: 'error_reporting', all: 1, plugin_setting: { disabled: false }
      expect(response).to redirect_to(plugin_path('error_reporting', all: 1))
      ps = PluginSetting.find_by!(name: 'error_reporting')
      expect(ps).to be_enabled
    end

    context "account_reports" do
      it 'can disable reports' do
        ps = PluginSetting.new(name: 'account_reports')
        ps.settings = { course_storage_csv: true }.with_indifferent_access
        ps.save!

        controller.stubs(:require_setting_site_admin).returns(true)
        put 'update', id: 'account_reports', all: 1, settings: { 'course_storage_csv' => '0' }
        expect(response).to redirect_to(plugin_path('account_reports', all: 1))
        ps.reload
        expect(ps.settings[:course_storage_csv]).to eq false
      end
    end
  end
end
