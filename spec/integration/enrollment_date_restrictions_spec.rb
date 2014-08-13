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
    @enrollment1 = course(:course_name => "Course 1", :active_all => 1)
    e1 = student_in_course(:user => @student, :active_all => 1)

    @enrollment2 = course(:course_name => "Course 2", :active_all => 1)

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
    page.css(".menu-item-drop-padded").should be_empty

    get "/courses"
    page = Nokogiri::HTML(response.body)
    active_enrollments = page.css(".current_enrollments tr")
    active_enrollments.length.should == 1
    # Make sure that the active coures have the star column.
    active_enrollments[0].css('td')[0]['class'].should match /star-column/

    page.css(".past_enrollments tr").should be_empty
  end

  it "should not show deleted enrollments in past enrollments when course is completed" do
    @student = user_with_pseudonym
    e1 = student_in_course(:user => @student, :active_all => 1)

    e1.destroy
    e1.workflow_state.should == 'deleted'

    @course.complete
    @course.workflow_state.should == 'completed'

    user_session(@student, @pseudonym)

    get "/courses"
    page = Nokogiri::HTML(response.body)
    page.css(".past_enrollments tr").should be_empty
  end

  it "should not list groups from inactive enrollments in the menu" do
    @student = user_with_pseudonym
    @course1 = course(:course_name => "Course 1", :active_all => 1)
    e1 = student_in_course(:user => @student, :active_all => 1)
    @group1 = @course1.groups.create(:name => "Group 1")
    @group1.add_user(@student)

    @course2 = course(:course_name => "Course 2", :active_all => 1)

    @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => true)
    e2 = student_in_course(:user => @student, :active_all => 1)
    @group2 = @course2.groups.create(:name => "Group 1")
    @group2.add_user(@student)

    user_session(@student, @pseudonym)

    get "/"
    page = Nokogiri::HTML(response.body)
    list = page.css(".menu-item-drop-column-list li").to_a
    # course lis are still there and view all groups should always show up when
    # there's at least one 'visible' group
    list.size.should == 3
    list.select{ |li| li.text =~ /Group 1/ }.should_not be_empty
    list.select{ |li| li.text =~ /View all groups/ }.should_not be_empty
    list.select{ |li| li.text =~ /Group 2/ }.should be_empty
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

    Account.default.account_users.create!(user: @user)
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
    @enrollment.reload.state_based_on_date.should == :inactive

    get '/calendar2'
    html = Nokogiri::HTML(response.body)
    html.css(".group_course_#{@course.id}").length.should == 0
  end
end
