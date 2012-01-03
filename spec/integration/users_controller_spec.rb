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

describe UsersController do
  describe "#teacher_activity" do
    before do
      course_with_teacher_logged_in(:active_all => true)
      @course.update_attribute(:name, 'coursename1')
      @teacher = @user
      @enrollment.update_attribute(:limit_privileges_to_course_section, true)
      @s1 = @course.course_sections.first
      @s2 = @course.course_sections.create!(:name => 'Section B')
      @e1 = student_in_course
      @e2 = student_in_course
      @e1.user.update_attribute(:name, 'studentname1')
      @e2.user.update_attribute(:name, 'studentname2')
      @e2.update_attribute(:course_section, @s2)
    end

    it "should count conversations as interaction" do
      get user_student_teacher_activity_url(@teacher, @e1.user)
      Nokogiri::HTML(response.body).at_css('table.report tr:first td:nth(2)').text.should match(/never/)

      @conversation = Conversation.initiate([@e1.user_id, @teacher.id], false)
      @conversation.add_message(@teacher, "hello")

      get user_student_teacher_activity_url(@teacher, @e1.user)
      Nokogiri::HTML(response.body).at_css('table.report tr:first td:nth(2)').text.should match(/less than 1 day/)
    end

    it "should only include students the teacher can view" do
      get user_course_teacher_activity_url(@teacher, @course)
      response.should be_success
      response.body.should match(/studentname1/)
      response.body.should_not match(/studentname2/)
    end

    it "should show user notes if enabled" do
      get user_course_teacher_activity_url(@teacher, @course)
      response.body.should_not match(/journal entry/i)
      @course.root_account.update_attribute(:enable_user_notes, true)
      get user_course_teacher_activity_url(@teacher, @course)
      response.body.should match(/journal entry/i)
    end

    it "should show individual user info across courses" do
      @course1 = @course
      @course2 = course(:active_course => true)
      @course2.update_attribute(:name, 'coursename2')
      student_in_course(:course => @course2, :user => @e1.user)
      get user_student_teacher_activity_url(@teacher, @e1.user)
      response.should be_success
      response.body.should match(/studentname1/)
      response.body.should_not match(/studentname2/)
      response.body.should match(/coursename1/)
      # teacher not in course2
      response.body.should_not match(/coursename2/)
      # now put teacher in course2
      @course2.enroll_teacher(@teacher).accept!
      get user_student_teacher_activity_url(@teacher, @e1.user)
      response.should be_success
      response.body.should match(/coursename1/)
      response.body.should match(/coursename2/)
    end
  end

  describe "#index" do
    it "should render" do
      user_with_pseudonym(:active_all => 1)
      @johnstclair = @user.update_attributes(:name => 'John St. Clair', :sortable_name => 'St. Clair, John')
      user_with_pseudonym(:active_all => 1, :username => 'jtolds@instructure.com', :name => 'JT Olds')
      @jtolds = @user
      Account.default.add_user(@user)
      user_session(@user, @pseudonym)
      get account_users_url(Account.default)
      response.should be_success
      response.body.should match /Olds, JT.*St\. Clair, John/m
    end
  end
end

