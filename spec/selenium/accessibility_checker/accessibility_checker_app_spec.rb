# frozen_string_literal: true

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

describe "Accessibility Checker App UI", type: :selenium do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @course.enable_feature!(:accessibility_tab_enable)
  end

  it "renders the Accessibility Checker App UI for a teacher" do
    get "/courses/#{@course.id}/accessibility"
    expect(element_exists?("#accessibility-checker-container")).to be true
  end
end
