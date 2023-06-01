# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"
require_relative "../setup/gradebook_setup"
require_relative "../../../feature_flag_helper"

describe "Gradebook - post grades to SIS" do
  include GradebookCommon
  include GradebookSetup
  include FeatureFlagHelper
  include_context "in-process server selenium tests"

  before(:once) do
    gradebook_data_setup
    create_sis_assignment
    show_sections_filter(@teacher)
  end

  before do
    user_session(@teacher)
  end

  after do
    clear_local_storage
  end

  def create_sis_assignment
    @assignment.post_to_sis = true
    @assignment.workflow_state = "published"
    @assignment.save
  end

  def export_plugin_setting
    plugin = Canvas::Plugin.find("grade_export")
    plugin_setting = PluginSetting.find_by(name: plugin.id)
    plugin_setting || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
  end

  def create_post_grades_tool(opts = {})
    course = opts[:course] || @course
    course.context_external_tools.create!(
      name: opts[:name] || "test tool",
      domain: "example.com",
      url: "http://example.com/lti",
      consumer_key: SecureRandom.hex,
      shared_secret: "secret",
      settings: {
        post_grades: {
          url: "http://example.com/lti/post_grades"
        }
      }
    )
  end

  describe "Plugin" do
    before(:once) { export_plugin_setting.update(disabled: false) }

    it "is not visible by default", priority: "1" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(f("body")).not_to contain_css("[data-menu-id='post_grades_feature_tool']")
    end

    it "is visible when enabled on course with sis_source_id" do
      mock_feature_flag(:post_grades, true)
      @course.sis_source_id = "xyz"
      @course.save

      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(f("body")).to contain_css("[data-menu-id='post_grades_feature_tool']")
    end

    it "does not show assignment errors when clicking the post grades button if all " \
       "assignments have due dates for each section",
       priority: "1" do
      mock_feature_flag(:post_grades, true)

      @course.update!(sis_source_id: "xyz")
      @course.course_sections.each do |section|
        @attendance_assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = "section override"
          override.due_at = Time.zone.now
          override.due_at_overridden = true
        end
      end
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector("post_grades_feature_tool").click

      expect(f(".post-grades-dialog")).not_to contain_css("#assignment-errors")
    end
  end

  describe "Plugin with enhanced filters enabed" do
    before(:once) do
      @course.enable_feature!(:enhanced_gradebook_filters)
      export_plugin_setting.update(disabled: false)
    end

    it "is not visible by default", priority: "1" do
      Gradebook.visit(@course)
      Gradebook.select_sync

      expect(f("body")).not_to contain_css("[data-menu-id='post_grades_feature_tool']")
    end

    it "is visible when enabled on course with sis_source_id" do
      mock_feature_flag(:post_grades, true)
      @course.sis_source_id = "xyz"
      @course.save

      Gradebook.visit(@course)
      Gradebook.select_sync

      expect(f("body")).to contain_css("[data-menu-id='post_grades_feature_tool']")
    end

    it "does not show assignment errors when clicking the post grades button if all " \
       "assignments have due dates for each section",
       priority: "1" do
      mock_feature_flag(:post_grades, true)

      @course.update!(sis_source_id: "xyz")
      @course.course_sections.each do |section|
        @attendance_assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = "section override"
          override.due_at = Time.zone.now
          override.due_at_overridden = true
        end
      end
      Gradebook.visit(@course)
      Gradebook.select_sync
      Gradebook.action_menu_item_selector("post_grades_feature_tool").click

      expect(f(".post-grades-dialog")).not_to contain_css("#assignment-errors")
    end
  end

  describe "LTI" do
    let!(:tool) { create_post_grades_tool }
    let(:tool_name) { "post_grades_lti_#{tool.id}" }

    it "shows when a post_grades lti tool is installed", priority: "1" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f("iframe.post-grades-frame")).to be_displayed
    end

    it "shows post grades lti button when only one section available" do
      course = Course.new(name: "Math 201", account: @account, sis_source_id: "xyz")
      course.save
      course.enroll_teacher(@user).accept!
      course.assignments.create!(name: "Assignment1", post_to_sis: true)
      create_post_grades_tool(course:)

      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f("iframe.post-grades-frame")).to be_displayed
    end

    it "does not hide post grades lti button when section selected", priority: "1" do
      create_post_grades_tool

      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      switch_to_section("the other section")
      Gradebook.open_action_menu

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed
    end
  end

  describe "LTI with enhanced filters enabled" do
    before(:once) do
      @course.enable_feature!(:enhanced_gradebook_filters)
    end

    let!(:tool) { create_post_grades_tool }
    let(:tool_name) { "post_grades_lti_#{tool.id}" }

    it "shows when a post_grades lti tool is installed", priority: "1" do
      Gradebook.visit(@course)
      Gradebook.select_sync

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f("iframe.post-grades-frame")).to be_displayed
    end

    # flakey; passes locally
    xit "shows post grades lti button when only one section available" do
      course = Course.new(name: "Math 201", account: @account, sis_source_id: "xyz")
      course.save
      course.enroll_teacher(@user).accept!
      course.assignments.create!(name: "Assignment1", post_to_sis: true)
      create_post_grades_tool(course:)

      Gradebook.visit(@course)
      Gradebook.select_sync

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f("iframe.post-grades-frame")).to be_displayed
    end
  end
end
