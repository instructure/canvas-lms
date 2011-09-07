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

describe "enrollment_date_restrictions" do
  it "should not list inactive enrollments in the menu" do
    @student = user_with_pseudonym
    course(:course_name => "Course 1", :active_all => 1)
    e1 = student_in_course(:user => @student, :active_all => 1)
    course(:course_name => "Course 2", :active_all => 1)
    @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => true)
    e2 = student_in_course(:user => @student, :active_all => 1)
    e1.state.should == :active
    e1.state_based_on_date.should == :active
    e2.state.should == :active
    e2.state_based_on_date.should == :inactive

    user_session(@student, @pseudonym)

    get "/"
    page = Nokogiri::HTML(response.body)
    list = page.css(".menu-item-drop-column-list li")
    list.length.should == 1
    list[0].text.should match /Course 1/
    list[0].text.should_not match /Course 2/
    page.css(".menu-item-drop-padded").should be_empty

    get "/courses"
    page = Nokogiri::HTML(response.body)
    active_enrollments = page.css(".current_enrollments li")
    active_enrollments.length.should == 1
    active_enrollments[0]['class'].should match /active/

    page.css(".past_enrollments li").should be_empty
  end

  it "should include see all enrollments link in menu for date completed courses" do
    @student = user_with_pseudonym
    course(:course_name => "Course 1", :active_all => 1)
    e1 = student_in_course(:user => @student, :active_all => 1)
    course(:course_name => "Course 2", :active_all => 1)
    @course.update_attributes(:start_at => 4.days.ago, :conclude_at => 2.days.ago, :restrict_enrollments_to_course_dates => true)
    e2 = student_in_course(:user => @student, :active_all => 1)
    e1.state.should == :active
    e1.state_based_on_date.should == :active
    e2.state.should == :active
    e2.state_based_on_date.should == :completed

    user_session(@student, @pseudonym)

    get "/"
    page = Nokogiri::HTML(response.body)
    list = page.css(".menu-item-drop-column-list li")
    list.length.should == 1
    list[0].text.should match /Course 1/
    list[0].text.should_not match /Course 2/
    page.css(".menu-item-drop-padded").should_not be_empty

    get "/courses"
    page = Nokogiri::HTML(response.body)
    active_enrollments = page.css(".current_enrollments li")
    active_enrollments.length.should == 1
    active_enrollments[0]['class'].should match /active/

    past_enrollments = page.css(".past_enrollments li")
    past_enrollments.length.should == 1
    past_enrollments[0]['class'].should match /completed/
  end

  it "should not show date inactive/completed courses in grades" do
    @course1 = course(:active_all => 1)
    @course2 = course(:active_all => 1)
    @course3 = course(:active_all => 1)
    @course4 = course(:active_all => 1)
    user(:active_all => 1)

    @course1.start_at = 4.days.ago
    @course1.conclude_at = 2.days.ago
    @course1.restrict_enrollments_to_course_dates = true
    @course1.save!

    @course2.start_at = 2.days.from_now
    @course2.conclude_at = 4.days.from_now
    @course2.restrict_enrollments_to_course_dates = true
    @course2.save!

    @course1.enroll_user(@user, 'StudentEnrollment', :enrollment_state => 'active')
    @course2.enroll_user(@user, 'StudentEnrollment', :enrollment_state => 'active')
    @course3.enroll_user(@user, 'StudentEnrollment', :enrollment_state => 'active')
    @course4.enroll_user(@user, 'StudentEnrollment', :enrollment_state => 'active')
    user_session(@user)

    get '/grades'
    html = Nokogiri::HTML(response.body)
    html.css('.course').length.should == 2

    Account.default.add_user(@user)
    get "/users/#{@user.id}"
    response.body.should match /Inactive/
    response.body.should match /Completed/
    response.body.should match /Active/
  end

  it "should not included date-inactive courses when searching for pertinent contexts" do
    course_with_teacher(:active_all => 1)
    student_in_course(:active_all => 1)
    user_session(@student)

    @course.start_at = 2.days.from_now
    @course.conclude_at = 4.days.from_now
    @course.restrict_enrollments_to_course_dates = true
    @course.save!
    @enrollment.state_based_on_date.should == :inactive

    get '/calendar'
    html = Nokogiri::HTML(response.body)
    html.css("#group_course_#{@course.id}").length.should == 0
  end
end
