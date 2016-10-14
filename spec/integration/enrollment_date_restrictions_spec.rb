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

require 'nokogiri'

describe "enrollment_date_restrictions" do
  before do
    Account.default.tap{|a| a.settings[:restrict_student_future_view] = {:value => true}}.save!
  end

  it "should not list inactive enrollments in the course list" do
    @student = user_with_pseudonym
    @enrollment1 = course(:course_name => "Course 1", :active_all => 1)
    e1 = student_in_course(:user => @student, :active_all => 1)

    @enrollment2 = course(:course_name => "Course 2", :active_all => 1)

    @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => true)
    e2 = student_in_course(:user => @student, :active_all => 1)
    expect(e1.state).to eq :active
    expect(e1.state_based_on_date).to eq :active
    expect(e2.state).to eq :active
    expect(e2.state_based_on_date).to eq :inactive

    user_session(@student, @pseudonym)

    get "/courses"
    page = Nokogiri::HTML(response.body)
    active_enrollments = page.css("#my_courses_table tbody tr")
    expect(active_enrollments.length).to eq 1
    # Make sure that the active courses have the star column.
    expect(active_enrollments[0].css('td')[0]['class']).to match /star-column/

    expect(page.css(".past_enrollments tr")).to be_empty
  end

  it "should not show deleted enrollments in past enrollments when course is completed" do
    @student = user_with_pseudonym
    e1 = student_in_course(:user => @student, :active_all => 1)

    e1.destroy
    expect(e1.workflow_state).to eq 'deleted'

    @course.complete
    expect(@course.workflow_state).to eq 'completed'

    user_session(@student, @pseudonym)

    get "/courses"
    page = Nokogiri::HTML(response.body)
    expect(page.css(".past_enrollments tr")).to be_empty
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
    expect(html.css('.course').length).to eq 2

    Account.default.account_users.create!(user: @user)
    @user.reload
    get "/users/#{@user.id}"
    expect(response.body).to match /Completed/
    expect(response.body).to match /Active/
  end

  it "should not included date-inactive courses when searching for pertinent contexts" do
    course_with_teacher(:active_all => 1)
    student_in_course(:active_all => 1)
    user_session(@student)

    @course.start_at = 2.days.from_now
    @course.conclude_at = 4.days.from_now
    @course.restrict_enrollments_to_course_dates = true
    @course.save!
    expect(@enrollment.reload.state_based_on_date).to eq :inactive

    get '/calendar2'
    html = Nokogiri::HTML(response.body)
    expect(html.css(".group_course_#{@course.id}").length).to eq 0
  end
end
