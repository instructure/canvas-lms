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

describe "/gradebooks/gradebook" do

  def test_grade_publishing(course_allows, permissions_allow)
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assign(:assignments, [a])
    assign(:students, [@user])
    assign(:submissions, [])
    assign(:gradebook_upload, '')
    assign(:body_classes, [])
    assign(:post_grades_tools, [])
    if course_allows && permissions_allow
      assign(:post_grades_tools, [{type: :post_grades}])
    end
    @course.expects(:allows_grade_publishing_by).with(@user).returns(course_allows)
    @course.expects(:grants_any_right?).returns(permissions_allow) if course_allows
    render "/gradebooks/gradebook"
    expect(response).not_to be_nil
    if course_allows && permissions_allow
      expect(response.body).to match /Publish grades to SIS/
    else
      expect(response.body).not_to match /Publish grades to SIS/
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

  describe "uploading scores" do
    before :each do
      course_with_teacher(:active_all => true)
      view_context
      assign(:gradebook_is_editable, true)
      assign(:assignments, [])
      assign(:students, [])
      assign(:submissions, [])
      assign(:gradebook_upload, '')
      assign(:body_classes, [])
      assign(:post_grades_tools, [])
    end

    it "should allow uploading scores for courses" do
      render "/gradebooks/gradebook"
      expect(response).not_to be_nil
      expect(response.body).to match /Import/
    end

    it "should not allow uploading scores for large roster courses" do
      @course.large_roster = true
      @course.save!
      @course.reload
      render "/gradebooks/gradebook"
      expect(response).not_to be_nil
      expect(response.body).not_to match /Import/
    end
  end

end
