# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../grades/pages/gradebook_page"
require_relative "../helpers/discussions_common"

describe "sync grades to sis" do
  include_context "in-process server selenium tests"

  before(:once) { export_plugin_setting.update(disabled: false) }

  before do
    course_with_admin_logged_in
    stub_rcs_config
    Account.default.set_feature_flag!("post_grades", "on")
    @course.sis_source_id = "xyz"
    @course.save
    @assignment_group = @course.assignment_groups.create!(name: "Assignment Group")
  end

  def export_plugin_setting
    plugin = Canvas::Plugin.find("grade_export")
    plugin_setting = PluginSetting.find_by(name: plugin.id)
    plugin_setting || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
  end

  it "does not display Sync to SIS option when feature not configured", priority: "1" do
    Account.default.set_feature_flag!("post_grades", "off")
    get "/courses/#{@course.id}/discussion_topics/new"
    f("#use_for_grading").click
    expect(f("#content")).not_to contain_css("#assignment_post_to_sis")
  end

  context "editing an existing topic with post_to_sis checked" do
    before do
      get "/courses/#{@course.id}/discussion_topics/new"
      f("#discussion-title").send_keys("New Discussion Title")
      f("#use_for_grading").click
      f("#assignment_post_to_sis").click
      wait_for_ajaximations
      click_option("#assignment_group_id", "Assignment Group")
      wait_for_new_page_load { submit_form(".form-actions") }

      @discussion_topic = DiscussionTopic.last
    end

    it "shows post grades to sis box checked", priority: "1" do
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}/edit"
      expect(f("#assignment_post_to_sis")).to be_enabled
    end
  end

  shared_examples "gradebook_sync_grades" do
    before do
      if @enhanced_filters
        @course.enable_feature!(:enhanced_gradebook_filters)
      end
      @assignment = @course.assignments.create!(name: "assignment",
                                                assignment_group: @assignment_group,
                                                post_to_sis: true)
    end

    def post_grades_dialog
      Gradebook.visit(@course)
      if @enhanced_filters
        Gradebook.select_sync
      else
        Gradebook.open_action_menu
      end
      expect(Gradebook.action_menu_item_selector("post_grades_feature_tool")).to be_displayed

      Gradebook.action_menu_item_selector("post_grades_feature_tool").click
      wait_for_ajaximations
      expect(f(".post-grades-dialog")).to be_displayed
    end

    it "syncs grades in a sync grades to SIS discussion", priority: "1" do
      @assignment.due_at = Time.zone.now.advance(days: 3)
      @course.discussion_topics.create!(user: @admin,
                                        title: "Sync to SIS discussion",
                                        message: "Discussion topic message",
                                        assignment: @assignment)
      post_grades_dialog
      expect(f(".assignments-to-post-count").text).to include("You are ready to sync 1 assignment")
    end

    it "asks for due dates in gradebook if due date is not given", :ignore_js_errors, priority: "1" do
      @course.discussion_topics.create!(user: @admin,
                                        title: "Sync to SIS discussion",
                                        message: "Discussion topic message",
                                        assignment: @assignment)
      due_at = 3.days.from_now
      post_grades_dialog
      expect(f("#assignment-errors").text).to include("1 Assignment with Errors")
      f(".assignment-due-at").send_keys(format_date_for_view(due_at))
      f(" .form-dialog-content").click
      f(".form-controls button[type=button]").click
      expect(f(".assignments-to-post-count")).to include_text("You are ready to sync 1 assignment")
    end
  end

  context "when enhanced filters is enabled" do
    before do
      @enhanced_filters = true
    end

    it_behaves_like "gradebook_sync_grades"
  end

  context "when enhanced filters is not enabled" do
    before do
      @enhanced_filters = false
    end

    it_behaves_like "gradebook_sync_grades"
  end
end
