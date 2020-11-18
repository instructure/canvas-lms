# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../common"
require_relative '../../helpers/public_courses_context'

describe "grades for a public course" do
  include_context "in-process server selenium tests"
  include_context "public course as a logged out user"

  it "should should prompt must be logged in when accessing /grades", priority: "1", test_id: 270031 do
    get "/grades"
    assert_flash_warning_message "You must be logged in to access this page"
    expect(driver.current_url).to eq app_url + "/login/canvas"
  end
end
