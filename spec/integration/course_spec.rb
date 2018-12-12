#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "course" do

  # normally this would be a controller test, but there is a some code in the
  # views that i need to not explode
  it "should not require authorization for public courses" do
    course_factory(active_all: true)
    @course.update_attribute(:is_public, true)
    get "/courses/#{@course.id}"
    expect(response).to be_successful
  end

  it "should load syllabus on public course with no user logged in" do
    course_factory(active_all: true)
    @course.update_attribute(:is_public, true)
    get "/courses/#{@course.id}/assignments/syllabus"
    expect(response).to be_successful
  end

  it "should show the migration-in-progress notice" do
    enable_cache do
      course_factory(active_all: true)
      user_session(@teacher)
      migration = @course.content_migrations.build
      migration.migration_settings[:import_in_progress_notice] = '1'
      migration.save!

      migration.update_attribute(:workflow_state, 'importing')
      get "/courses/#{@course.id}"
      expect(response).to be_successful
      expect(controller.js_env[:CONTENT_NOTICES].map { |cn| cn[:tag] }).to include :import_in_progress

      migration.update_attribute(:workflow_state, 'imported')
      get "/courses/#{@course.id}"
      expect(response).to be_successful
      expect((controller.js_env[:CONTENT_NOTICES] || []).map { |cn| cn[:tag] }).not_to include :import_in_progress
    end
  end

  it "should not show the migration-in-progress notice to students" do
    enable_cache do
      course_factory(active_all: true)
      student_in_course active_all: true
      user_session(@student)
      migration = @course.content_migrations.build
      migration.migration_settings[:import_in_progress_notice] = '1'
      migration.save!

      migration.update_attribute(:workflow_state, 'importing')
      get "/courses/#{@course.id}"
      expect(response).to be_successful
      expect((controller.js_env[:CONTENT_NOTICES] || []).map { |cn| cn[:tag] }).not_to include :import_in_progress
    end
  end

  it "should use nicknames in the course index" do
    course_with_student(:active_all => true, :course_name => "Course 1")
    course_with_student(:user => @student, :active_all => true, :course_name => "Course 2")
    @student.course_nicknames[@course.id] = 'A nickname or something'
    @student.save!
    user_session(@student)
    get "/courses"
    doc = Nokogiri::HTML(response.body)
    course_rows = doc.css('#my_courses_table tr')
    expect(course_rows.size).to eq 3
    expect(course_rows[1].to_s).to include 'A nickname or something'
    expect(course_rows[2].to_s).to include 'Course 1'
  end

  it "should not show links to unpublished courses in course index" do
    course_with_student(:course_name => "Course 1")
    c1 = @course
    @student.enrollments.first.update_attribute(:workflow_state, "active") # force active, like with sis
    course_with_student(:user => @student, :active_all => true, :course_name => "Course 2")
    c2 = @course
    user_session(@student)
    get "/courses"
    doc = Nokogiri::HTML(response.body)
    course_rows = doc.css('#my_courses_table tr')
    expect(course_rows.size).to eq 3
    expect(course_rows[1].to_s).to include 'Course 1'
    expect(course_rows[1].to_s).to_not include("href=\"/courses/#{c1.id}\"") # unpublished
    expect(course_rows[2].to_s).to include 'Course 2'
    expect(course_rows[2].to_s).to include("href=\"/courses/#{c2.id}\"") # published
  end

  it "should not show students' nicknames to admins on the student's account profile page" do
    course_with_student(:active_all => true)
    @student.course_nicknames[@course.id] = 'STUDENT_NICKNAME'; @student.save!
    user_session(account_admin_user)
    get "/accounts/#{@course.root_account.id}/users/#{@student.id}"
    doc = Nokogiri::HTML(response.body)
    course_list = doc.at_css('#courses_list').to_s
    expect(course_list).not_to include 'STUDENT_NICKNAME'
  end
end
