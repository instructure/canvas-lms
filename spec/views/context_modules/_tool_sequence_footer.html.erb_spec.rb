#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative "../views_helper"

describe "_tool_sequence_footer" do
  before(:once) do
    course_with_ta
    @content_tag = ContentTag.new
    assignment = @course.assignments.create!(title: "an assignment")
    @content_tag.assignment = assignment
    assign(:tag, @content_tag)
  end

  context "when user can view speedgrader" do
    before(:each) do
      view_context(@course, @ta)
    end

    it "renders a speedgrader link container if user can view speedgrader" do
      render partial: "context_modules/tool_sequence_footer"
      expect((content_for :right_side)).to have_tag("div[id='speed_grader_link_container']")
    end

    it "renders a student group container if user can view speedgrader" do
      render partial: "context_modules/tool_sequence_footer"
      expect((content_for :right_side)).to have_tag("div[id='student_group_filter_container']")
    end
  end

  context "when user cannot view speedgrader" do
    before(:each) do
      view_context(@course, @ta)
      @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
      @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
    end

    it "does not render a speedgrader link container if user cannot view speedgrader" do
      render partial: "context_modules/tool_sequence_footer"
      expect((content_for :right_side)).not_to have_tag("div[id='speed_grader_link_container']")
    end

    it "does not render a student group container if user cannot view speedgrader" do
      render partial: "context_modules/tool_sequence_footer"
      expect((content_for :right_side)).not_to have_tag("div[id='student_group_filter_container']")
    end
  end
end
