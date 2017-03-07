#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/courses/index" do
  it "should render" do
    course_with_student
    view_context
    assign(:current_enrollments, [@enrollment])
    assign(:past_enrollments, [])
    assign(:future_enrollments, [])
    assign(:visible_groups, [])
    render "courses/index"
    expect(response).not_to be_nil
  end

  it "should show context name in groups table" do
    course_with_student
    group_with_user(:user => @user, :group_context => @course)
    view_context
    assign(:current_enrollments, [@enrollment])
    assign(:past_enrollments, [])
    assign(:future_enrollments, [])
    assign(:visible_groups, [@group])
    render "courses/index"
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css('#my_groups_table td:nth-child(2) span.name').text).to eq @course.name
  end

  it "should not show groups for restricted future courses" do
    term = EnrollmentTerm.new(:name => "term", :start_at => 1.week.from_now, :end_at => 1.month.from_now)
    course_with_student
    @course.restrict_student_future_view = true
    @course.update_attributes!(:enrollment_term => term)

    group_with_user(:user => @user, :group_context => @course)
    view_context
    assign(:current_enrollments, [])
    assign(:past_enrollments, [])
    assign(:future_enrollments, [@enrollment])
    assign(:visible_groups, [])
    render "courses/index"
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css('#my_groups_table')).to be_nil
  end
end
