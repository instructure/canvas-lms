# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../helpers/k5_common"
require_relative "pages/course_index_page"

describe "course index" do
  include_context "in-process server selenium tests"
  include K5Common
  include CourseIndexPage

  before :once do
    @classic_account = Account.create!(name: "Classic", parent_account: Account.default)
    @k5_account = Account.create!(name: "Elementary", parent_account: Account.default)
    toggle_k5_setting(@k5_account)
    @user = User.create!

    @current_courses = []
    @current_courses << course_with_student(course_name: "Classic Course (Current)", account: @classic_account, user: @user, active_all: true).course
    @current_courses << course_with_student(course_name: "K5 Course (Current)", account: @k5_account, user: @user, active_all: true).course

    @past_courses = []
    @past_courses << course_with_student(course_name: "Classic Course (Past)", account: @classic_account, user: @user, active_all: true).course
    @past_courses << course_with_student(course_name: "K5 Course (Past)", account: @k5_account, user: @user, active_all: true).course
    @past_courses.each(&:complete!)

    @future_courses = []
    @future_courses << course_with_student(course_name: "Classic Course (Future)", account: @classic_account, user: @user).course
    @future_courses << course_with_student(course_name: "K5 Course (Future)", account: @k5_account, user: @user).course
    @future_courses.each do |c|
      c.start_at = 1.week.from_now
      c.conclude_at = 6.weeks.from_now
      c.restrict_enrollments_to_course_dates = true
      c.save!
      c.offer!
    end
    @user.enrollments.where(course: @future_courses).update_all(workflow_state: "active")
  end

  before do
    user_session(@user)
    instance_variable_set(:@current_user, @user)
    instance_variable_set(:@domain_root_account, Account.default)
  end

  context "title" do
    it "shows All Subjects when user is enrolled in a k5 course" do
      get "/courses"

      expect(header).to include_text("All Subjects")
    end

    it "shows All Courses when user is not enrolled in a k5 course" do
      @user.enrollments.where.not(course: @current_courses[0]).destroy_all
      get "/courses"

      expect(header).to include_text("All Courses")
    end
  end

  context "favorites column" do
    it "is visible when at least one classic course exists" do
      get "/courses"

      expect(current_enrollments).to contain_css(favorites_column_selector)
      expect(past_enrollments).to contain_css(favorites_column_selector)
      expect(future_enrollments).to contain_css(favorites_column_selector)
    end

    it "is not visible if there's just k5 courses" do
      @user.enrollments.where(course: [@current_courses[0], @past_courses[0], @future_courses[0]]).destroy_all
      get "/courses"

      expect(current_enrollments).to contain_css(title_column_selector)
      expect(past_enrollments).to contain_css(title_column_selector)
      expect(future_enrollments).to contain_css(title_column_selector)

      expect(current_enrollments).not_to contain_css(favorites_column_selector)
      expect(past_enrollments).not_to contain_css(favorites_column_selector)
      expect(future_enrollments).not_to contain_css(favorites_column_selector)
    end

    it "displays stars only next to classic courses" do
      get "/courses"

      star = ".course-list-favoritable"
      ["Classic Course (Current)", "Classic Course (Past)", "Classic Course (Future)"].each do |name|
        expect(row_with_text(name)).to contain_css(star)
      end

      ["K5 Course (Current)", "K5 Course (Past)", "K5 Course (Future)"].each do |name|
        expect(row_with_text(name)).not_to contain_css(star)
      end
    end

    it "includes the course title in the star's text" do
      get "/courses"

      expect(fj('.course-list-favoritable:contains("Click to add Classic Course (Current) to the courses menu.")')).to be_displayed
      expect(fj('.course-list-favoritable:contains("Classic Course (Past) cannot be added to the courses menu unless the course is active.")')).to be_displayed
      expect(fj('.course-list-favoritable:contains("Click to add Classic Course (Future) to the courses menu.")')).to be_displayed
    end

    it "favorites a course" do
      get "/courses"

      course_name = "Classic Course (Current)"
      expect(row_with_text(course_name)).not_to contain_css(".icon-star")
      favorite_icon(course_name).click
      wait_for_ajaximations
      expect(row_with_text(course_name)).to contain_css(".icon-star")
    end

    it "unfavorites a course" do
      @user.favorites.create!(context: @current_courses[0])
      get "/courses"

      course_name = "Classic Course (Current)"
      expect(row_with_text(course_name)).to contain_css(".icon-star")
      favorite_icon(course_name).click
      wait_for_ajaximations
      expect(row_with_text(course_name)).not_to contain_css(".icon-star")
    end
  end

  context "start new course button" do
    it "launches k5 dialog for k5 users" do
      course_with_teacher_logged_in(account: @k5_account)
      @teacher.account.settings[:teachers_can_create_courses] = true
      @teacher.account.save!

      get "/courses"
      add_course_button = f("#start_new_course")
      expect(add_course_button).to include_text("Subject")
      add_course_button.click
      expect(fj('h2:contains("Create Subject")')).to be_displayed
    end

    it "launches classic new course dialog for non-k5 users" do
      course_with_teacher_logged_in(account: @classic_account)
      @teacher.account.settings[:teachers_can_create_courses] = true
      @teacher.account.save!

      get "/courses"
      add_course_button = f("#start_new_course")
      expect(add_course_button).to include_text("Course")
      add_course_button.click
      expect(fj('.ui-dialog-title:contains("Start a New Course")')).to be_displayed
    end

    it "launches improved new course dialog for non-k5 users if create_course_subaccount_picker is enabled" do
      @classic_account.root_account.enable_feature!(:create_course_subaccount_picker)
      course_with_teacher_logged_in(account: @classic_account)
      @teacher.account.settings[:teachers_can_create_courses] = true
      @teacher.account.save!

      get "/courses"
      add_course_button = f("#start_new_course")
      expect(add_course_button).to include_text("Course")
      add_course_button.click
      expect(fj('h2:contains("Create Course")')).to be_displayed
    end
  end
end
