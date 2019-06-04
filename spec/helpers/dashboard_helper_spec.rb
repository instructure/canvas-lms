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

describe DashboardHelper do
  include DashboardHelper

  context "show_welcome_message?" do
    it "should be true if the user has no current enrollments" do
      user_model
      @current_user = @user
      expect(show_welcome_message?()).to be_truthy
    end

    it "should be false otherwise" do
      course_with_student(:active_all => true)
      @current_user = @student
      expect(show_welcome_message?()).to be_falsey
    end
  end

  context "user_dashboard_view" do
    before :once do
      course_with_student(:active_all => true)
      @current_user = @student
    end

    it "should use the account's default dashboard view setting if the user has not selected one" do
      @current_user.dashboard_view = nil
      @current_user.save!
      @course.account.default_dashboard_view = 'activity'
      @course.account.save!
      expect(user_dashboard_view).to eq 'activity'
    end

    it "should return 'planner' if set" do
      @course.root_account.enable_feature!(:student_planner)
      @current_user.dashboard_view = 'planner'
      @current_user.save!
      expect(user_dashboard_view).to eq 'planner'
    end

    it "should be backwards compatible with the deprecated 'show_recent_activity' preference" do
      @current_user.preferences[:recent_activity_dashboard] = true
      @current_user.save!
      expect(user_dashboard_view).to eq 'activity'
    end

    it "should return the correct value based on the user's setting" do
      @current_user.dashboard_view = 'cards'
      @current_user.save!
      expect(user_dashboard_view).to eq 'cards'

      @current_user.dashboard_view = 'activity'
      @current_user.save!
      expect(user_dashboard_view).to eq 'activity'
    end
  end

  describe "map_courses_for_menu" do
    context "Dashcard Reordering" do
      before(:each) do
        @account = Account.default
        @domain_root_account = @account
      end

      it "returns the list of courses sorted by position" do
        course1 = @account.courses.create!
        course2 = @account.courses.create!
        course3 = @account.courses.create!
        user = user_model
        course1.enroll_student(user)
        course2.enroll_student(user)
        course3.enroll_student(user)
        courses = [course1, course2, course3]
        user.dashboard_positions[course1.asset_string] = 3
        user.dashboard_positions[course2.asset_string] = 2
        user.dashboard_positions[course3.asset_string] = 1
        user.save!
        @current_user = user
        mapped_courses = map_courses_for_menu(courses)
        expect(mapped_courses.map {|h| h[:id]}).to eq [course3.id, course2.id, course1.id]
      end
    end
  end
end
