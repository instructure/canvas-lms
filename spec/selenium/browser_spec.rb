# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative 'common'

describe "browser" do
  include_context "in-process server selenium tests"

  it "pulls logs" do
    skip_if_ie('not supported')
    skip_if_firefox('not supported')
    skip_if_safari('not supported')

    sample_msg = '=== Test Logging ==='

    get('/login')
    driver.execute_script("window.console.log('#{sample_msg}')")
    browser_logs = driver.manage.logs.get(:browser)

    expect(browser_logs.map(&:message)).to include(a_string_matching(sample_msg))
  end
end
