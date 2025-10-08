# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "Sessions Timeout" do
  include_context "in-process server selenium tests"

  it "logs the user out after the session is expired" do
    plugin_setting = PluginSetting.new(name: "sessions", settings: { "session_timeout" => "1" })
    plugin_setting.save!
    user_with_pseudonym({ active_user: true })
    login_as
    expect(f('[aria-label="Profile tray"] h2').text).to eq @user.pseudonyms.first.unique_id

    Timecop.travel(61.seconds.from_now) do
      get "/courses"

      assert_flash_warning_message("You must be logged in to access this page")
    end
  end
end
