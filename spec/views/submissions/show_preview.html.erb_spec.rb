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

describe "/submissions/show_preview" do
  it "should render" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show_preview"
    expect(response).not_to be_nil
  end

  it "should load an lti launch" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "external assignment", :submission_types => 'basic_lti_launch')
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user, submission_type: 'basic_lti_launch', url: 'http://www.example.com'))
    render "submissions/show_preview"
    expect(response.body).to match(/courses\/#{@course.id}\/external_tools\/retrieve/)
    expect(response.body).to match(/.*www\.example\.com.*/)
  end

  it "should give a user-friendly explaination why there's no preview" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment", :submission_types => 'on_paper')
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show_preview"
    expect(response.body).to match(/No Preview Available/)
  end
end

