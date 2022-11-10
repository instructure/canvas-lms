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

describe "groups/index" do
  it "renders" do
    course_with_student
    view_context
    assign(:categories, [])
    assign(:students, [@user])
    assign(:memberships, [])
    assign(:current_groups, [])
    assign(:previous_groups, [])
    render "groups/index"
    expect(response).not_to be_nil
  end

  it "shows context name under group name" do
    course_with_student
    group_with_user(user: @user, group_context: @course)
    view_context
    assign(:categories, [])
    assign(:students, [@user])
    assign(:memberships, [])
    assign(:current_groups, [@group])
    assign(:previous_groups, [])
    render "groups/index"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css("#current_groups_table td:nth-child(2) span.group-course-name").text).to eq @course.name
    expect(doc.at_css("#current_groups_table td:nth-child(1)").text.strip).to eq @group.name
    expect(doc.at_css("#current_groups_table td:nth-child(1) a").text.strip).not_to be_nil
  end

  it "does not display a link for a concluded course" do
    course_with_student
    group_with_user(user: @user, group_context: @course)
    @course.do_complete
    view_context
    assign(:categories, [])
    assign(:students, [@user])
    assign(:memberships, [])
    assign(:current_groups, [])
    assign(:previous_groups, [@group])
    render "groups/index"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css("#previous_groups_table td:nth-child(1)").text.strip).to eq @group.name
    expect(doc.at_css("#previous_groups_table td:nth-child(1) a")).to be_nil
  end
end
