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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../apis/api_spec_helper')

describe CoursesController, type: :request do
  it "should cache the course wizard based on the current user" do
    enable_cache do
      course_with_teacher(:active_enrollment => true, :name => 'unpublished course')
      teacher = @user

      user_model
      ta = @user
      @course.enroll_ta(ta).accept

      @course.reload
      user_session(ta)
      get "/courses/#{@course.id}"
      expect(response).to be_success

      # We do a page load before the test because something during the first load
      # will touch the course, invalidating the cache anyway and making this test
      # silly. After the first page load, we perform our test and verify that the
      # course is not touched in the meantime.
      original_course_updated_at = @course.reload.updated_at

      get "/courses/#{@course.id}"
      expect(response).to be_success
      page = Nokogiri::HTML(response.body)
      expect(page.css(".wizard_options_list li.publish_step").length).to eq 0

      user_session(teacher)
      get "/courses/#{@course.id}"
      expect(response).to be_success
      page = Nokogiri::HTML(response.body)
      expect(page.css(".wizard_options_list li.publish_step").length).to eq 1
      expect(@course.reload.updated_at).to eq original_course_updated_at
    end
  end
end
