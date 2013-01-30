#
# Copyright (C) 2012 Instructure, Inc.
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

describe "courses/_settings_sidebar.html.erb" do
  describe "End this course button" do
    before do
      course_with_teacher(:active_all => true)
      @course.sis_source_id = "so_special_sis_id"
      @course.workflow_state = 'claimed'
      @course.save!
      assigns[:context] = @course
      assigns[:user_counts] = {}
      assigns[:all_roles] = Role.custom_roles_and_counts_for_course(@course, @user)
    end

    it "should not display if the course or term end date has passed" do
      @course.stubs(:soft_concluded?).returns(true)
      view_context(@course, @user)
      assigns[:current_user] = @user
      render
      response.body.should_not match(/Conclude this Course/)
    end

    it "should display if the course and its term haven't ended" do
      @course.stubs(:soft_concluded?).returns(false)
      view_context(@course, @user)
      assigns[:current_user] = @user
      render
      response.body.should match(/Conclude this Course/)
    end
  end
end
