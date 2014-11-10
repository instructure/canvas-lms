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

describe "/gradebooks/speed_grader" do
  before do
    course_with_student
    view_context
    assigns[:students] = [@user]
    assigns[:assignment] = @course.assignments.create!(:title => "some assignment")
    assigns[:submissions] = []
    assigns[:assessments] = []
    assigns[:body_classes] = []
  end

  it "should render" do
    render "gradebooks/speed_grader"
    expect(response).not_to be_nil
  end

  it "includes a link back to the gradebook (gradebook2 by default)" do
    render "gradebooks/speed_grader"
    course_id = @course.id
    expect(response.body).to include "a href=\"http://test.host/courses/#{course_id}/gradebook\""
  end
end

