#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradezilla_common')


describe "large enrollments", priority: "2" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  context "page links" do

    before(:each) do
      course_with_teacher_logged_in

      create_users_in_course @course, 500
    end

    it "should display course homepage" do
      get "/courses/#{@course.id}/"
      expect_no_flash_message :error
    end

  end
end
