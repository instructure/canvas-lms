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

  describe "show_recent_activity?" do
    before(:once) do
      course_with_student(:active_all => true)
      @current_user = @student
    end

    it "should be false if preferences[:dashboard_view] is not set" do
      @current_user.preferences.delete(:dashboard_view)
      @current_user.preferences.delete(:recent_activity_dashboard)
      expect(show_recent_activity?).to be_falsey
    end

    it "should be false if preferences[:dashboard_view] is not activity" do
      @current_user.preferences[:dashboard_view] = 'something_that_isnt_activity'
      @current_user.preferences.delete(:recent_activity_dashboard)
      expect(show_recent_activity?).to be_falsey
    end

    it "should be true if preferences[:dashboard_view] is activity" do
      @current_user.preferences[:dashboard_view] = 'activity'
      @current_user.preferences.delete(:recent_activity_dashboard)
      expect(show_recent_activity?).to be_truthy
    end

    it "should be true if preferences[:recent_activity_dashboard] is true" do
      @current_user.preferences.delete(:dashboard_view)
      @current_user.preferences[:recent_activity_dashboard] = true
      expect(show_recent_activity?).to be_truthy
    end
  end

  describe "show_dashboard_cards?" do
    before(:once) do
      course_with_student(:active_all => true)
      @current_user = @student
    end

    it "should be true if preferences[:dashboard_view] is not set" do
      @current_user.preferences.delete(:dashboard_view)
      @current_user.preferences.delete(:recent_activity_dashboard)
      expect(show_dashboard_cards?).to be_truthy
    end

    it "should be false if preferences[:dashboard_view] is not cards" do
      @current_user.preferences[:dashboard_view] = 'something_that_isnt_cards'
      @current_user.preferences.delete(:recent_activity_dashboard)
      expect(show_dashboard_cards?).to be_falsey
    end

    it "should be true if preferences[:dashboard_view] is cards" do
      @current_user.preferences[:dashboard_view] = 'cards'
      @current_user.preferences.delete(:recent_activity_dashboard)
      expect(show_dashboard_cards?).to be_truthy
    end

    it "should be true if preferences[:recent_activity_dashboard] is false" do
      @current_user.preferences.delete(:dashboard_view)
      @current_user.preferences[:recent_activity_dashboard] = false
      expect(show_dashboard_cards?).to be_truthy
    end
  end

end
