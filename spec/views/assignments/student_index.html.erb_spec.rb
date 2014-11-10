#
# Copyright (C) 2011 Instructure, Inc.
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

describe "/assignments/student_index" do
  it "should render" do
    course_with_student
    view_context(@course, @user)
    g = @course.assignment_groups.create!(:name => "some group")
    a = @course.assignments.create!(:title => "some assignment")
    a.assignment_group_id = g.id
    a.save!
    assigns[:assignments] = [a]
    assigns[:assignment_groups] = [g]
    assigns[:groups] = [g]
    assigns[:courses] = [@course]
    assigns[:just_viewing_just_one_course] = true
    assigns[:ungraded_assignments] = []
    assigns[:upcoming_assignments] = []
    assigns[:undated_assignments] = []
    assigns[:future_assignments] = []
    assigns[:past_assignments] = []
    assigns[:overdue_assignments] = []
    assigns[:submissions] = []
    render 'assignments/student_index'
    expect(response).not_to be_nil
  end
end

