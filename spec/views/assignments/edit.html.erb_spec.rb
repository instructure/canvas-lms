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

require_relative "../views_helper"

describe "assignments/edit" do
  before do
    course_with_teacher(active_all: true)
    view_context(@course, @user)
    group = @course.assignment_groups.create!(name: "some group")
    @assignment = @course.assignments.create!(
      title: "some assignment",
      submission_types: "external_tool"
    )
    @assignment.assignment_group_id = group.id
    @assignment.save!
    assign(:assignment, @assignment)
    assign(:assignment_groups, [group])
    assign(:current_user_rubrics, [])
  end

  it "renders" do
    render "assignments/edit"
    expect(response).not_to be_nil # have_tag()
  end

  it "renders rubrics" do
    allow(@assignment).to receive(:quiz_lti?).and_return(true)
    render "assignments/edit"
    expect(response).to render_template(partial: "_rubrics_component")
  end
end
