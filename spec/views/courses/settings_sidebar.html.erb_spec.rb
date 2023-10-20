# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "courses/_settings_sidebar" do
  before do
    course_with_teacher(active_all: true)
    @course.sis_source_id = "so_special_sis_id"
    @course.workflow_state = "claimed"
    @course.save!
    assign(:context, @course)
    assign(:user_counts, {})
    assign(:all_roles, Role.custom_roles_and_counts_for_course(@course, @user))
    assign(:course_settings_sub_navigation_tools, [])
  end

  describe "End this course button" do
    it "does not display if the course or term end date has passed" do
      @course.update conclude_at: 1.day.ago, restrict_enrollments_to_course_dates: true
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      expect(response.body).not_to match(/Conclude this Course/)
    end

    it "displays if the course and its term haven't ended" do
      @course.update conclude_at: 1.day.from_now, restrict_enrollments_to_course_dates: true
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      expect(response.body).to match(/Conclude this Course/)
    end
  end

  describe "Reset course content" do
    it "does not display the dialog contents under the button (granular permissions)" do
      @course.account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        permission: "manage_courses_reset",
        role: teacher_role,
        enabled: true
      )
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      doc = Nokogiri.HTML5(response.body)
      expect(doc.at_css("#reset_course_content_dialog")["style"]).to eq "display:none;"
    end
  end

  describe "course settings sub navigation" do
    before do
      view_context(@course, @user)
      assign(:current_user, @user)
      @controller.instance_variable_set(:@context, @course)
    end

    describe "external tools" do
      def create_course_settings_sub_navigation_tool(options = {})
        defaults = {
          name: options[:name] || "external tool",
          consumer_key: "test",
          shared_secret: "asdf",
          url: "http://example.com/ims/lti",
          course_settings_sub_navigation: { icon_url: "/images/delete.png" },
        }
        @course.context_external_tools.create!(defaults.merge(options))
      end

      it "displays all configured tools" do
        num_tools = 3
        (1..num_tools).each do |n|
          create_course_settings_sub_navigation_tool(name: "tool #{n}")
        end
        assign(:course_settings_sub_navigation_tools, @course.context_external_tools.to_a)
        render
        doc = Nokogiri::HTML5(response.body)
        expect(doc.css(".course-settings-sub-navigation-lti").size).to eq num_tools
      end

      it "includes the launch type parameter" do
        create_course_settings_sub_navigation_tool
        assign(:course_settings_sub_navigation_tools, @course.context_external_tools.to_a)
        render
        doc = Nokogiri::HTML5(response.body)
        tool_link = doc.at_css(".course-settings-sub-navigation-lti")
        expect(tool_link["href"]).to include("launch_type=course_settings_sub_navigation")
      end

      it "does not have additional spacing between an icon and a label" do
        create_course_settings_sub_navigation_tool
        assign(:course_settings_sub_navigation_tools, @course.context_external_tools.to_a)
        render
        doc = Nokogiri::HTML5(response.body)
        tool_link = doc.at_css(".course-settings-sub-navigation-lti")
        expect(tool_link.to_html).to include("<img class=\"icon\" alt=\"\" src=\"/images/delete.png\">external tool")
      end
    end
  end
end
