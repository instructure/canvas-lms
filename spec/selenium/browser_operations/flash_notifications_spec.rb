# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe "flash notifications" do
  include_context "in-process server selenium tests"

  it "shows unsupported browser message but allow you to dismiss it", :ignore_js_errors do
    # fix console errors in DE-186 (8/10/2020)
    allow_any_instance_of(ApplicationController).to receive(:browser_supported?).and_return(false)
    get "/login"
    expect(f(flash_message_selector)).to include_text "Your browser does not meet the minimum requirements for Canvas"
    dismiss_flash_messages

    get "/login"
    expect(f("body")).not_to contain_css(flash_message_selector)
  end
end
