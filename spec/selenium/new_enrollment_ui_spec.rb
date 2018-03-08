#
# Copyright (C) 2017 - present Instructure, Inc.
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
require_relative 'new_enrollment_page_object_model'

describe "New Enrollment" do
  include_context "in-process server selenium tests"
  include EnrollmentPageObject

  before :once do
    course_with_teacher(active_all: true, new_user: true)
    @section1 = @course.course_sections.create!(:name => 'Section 1')
    @user1 = user_with_pseudonym(name: "user1")
    @user1.communication_channels.create(path: "user1@example.com", path_type: 'email').confirm
    @user2 = user_with_pseudonym(name: "user2")
    @user2.communication_channels.create(path: "user2@example.com", path_type: 'email').confirm
  end

  it "opens new enroll dialog", priority: "1", test_id: 3077472 do
    user_session(@teacher)
    get "/courses/#{@course.id}/users"
    add_people_button.click
    expect(add_people_modal).to be_displayed
    expect(next_button).to have_attribute('aria-disabled', 'true')
  end

  it "adds new users", priority: "1", test_id: 3077477 do
    user_session(@teacher)
    get "/courses/#{@course.id}/users"
    add_people_button.click
    f('textarea').send_keys(@user1.communication_channels.last.path + ', ' + @user2.communication_channels.last.path)
    next_button.click
    expect(peopleready_info_box.text).to include('The following users are ready to be added to the course')
    expect(name_to_be_added(1)).to include(@user1.name)
    expect(name_to_be_added(2)).to include(@user2.name)
    next_button.click
    # find users int he roster. Admin and teacher are enrolled already
    expect(course_roster(3)).to contain_link(@user1.name.to_s)
    expect(course_roster(4)).to contain_link(@user2.name.to_s)
  end
end
