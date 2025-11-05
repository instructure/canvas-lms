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

require_relative "../common"
require_relative "pages/microfrontends_override_page"

describe "Microfrontend Release Tag Override" do
  include_context "in-process server selenium tests"
  include MicrofrontendsOverridePage

  before do
    Setting.set("allow_microfrontend_release_tag_override", "true")
    course_with_teacher_logged_in
  end

  it "shows the override indicator when navigating to the override URL" do
    get "/api/v1/microfrontends/release_tag_override?override[canvas_career_learner]=https://assets.instructure.com/test"

    expect(override_indicator).to be_displayed
    expect(override_indicator.text).to include("MFE Overrides Active")
    expect(override_indicator.text).to include("canvas_career_learner")
    expect(override_indicator.text).to include("https://assets.instructure.com/test")
  end

  it "clears overrides and navigates back when clicking clear button" do
    get "/api/v1/microfrontends/release_tag_override?override[canvas_career_learner]=https://assets.instructure.com/test"

    expect(override_indicator).to be_displayed

    clear_button.click

    wait_for_ajaximations

    expect(driver.current_url).to match(%r{/$})
    expect(f("body")).not_to contain_css(override_indicator_selector)
  end

  it "handles multiple overrides" do
    get "/api/v1/microfrontends/release_tag_override?override[canvas_career_learner]=https://assets.instructure.com/test1&override[canvas_career_learning_provider]=https://assets.instructure.com/test2"

    expect(override_indicator).to be_displayed
    expect(override_indicator.text).to include("canvas_career_learner")
    expect(override_indicator.text).to include("https://assets.instructure.com/test1")
    expect(override_indicator.text).to include("canvas_career_learning_provider")
    expect(override_indicator.text).to include("https://assets.instructure.com/test2")
  end
end
