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

describe "/gradebooks/_gradebook" do
  it "should render" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assigns[:assignments] = [a]
    assigns[:students] = [@user]
    assigns[:submissions] = []
    assigns[:gradebook_upload] = @course.build_gradebook_upload      
    render :partial => "gradebooks/gradebook"
    response.should_not be_nil
  end

  def test_grade_publishing(course_allows, permissions_allow)
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assigns[:assignments] = [a]
    assigns[:students] = [@user]
    assigns[:submissions] = []
    assigns[:gradebook_upload] = @course.build_gradebook_upload
    @course.expects(:allows_grade_publishing_by).with(@user).returns(course_allows)
    @course.expects(:grants_rights?).with(@user, {}, nil).returns(permissions_allow ? {:manage_grades=>true} : {}) if course_allows
    render :partial => "gradebooks/gradebook"
    response.should_not be_nil
    if course_allows && permissions_allow
      response.body.should =~ /var sisPublishEnabled = true;\n/
    else
      response.body.should =~ /var sisPublishEnabled = false;\n/
    end
  end

  it "should enable grade publishing when appropriate" do
    test_grade_publishing(true, true)
  end

  it "should disable grade publishing when the course disallows it" do
    test_grade_publishing(false, true)
  end

  it "should disable grade publishing when permissions disallow it" do
    test_grade_publishing(true, false)
  end
end
