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

require_relative "../../feature_flag_helper"
require_relative "../grades/pages/gradebook_page"
require_relative "../helpers/discussions_common"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "sync grades to sis" do |ff_enabled|
  include FeatureFlagHelper
  include_context "in-process server selenium tests"

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  before do
    course_with_admin_logged_in
    mock_feature_flag(:post_grades, true)
    @course.sis_source_id = "xyz"
    @course.save
    @assignment_group = @course.assignment_groups.create!(name: "Assignment Group")
  end

  context "editing an existing topic with post_to_sis checked" do
    before do
      get "/courses/#{@course.id}/discussion_topics/new"
      f("#discussion-title").send_keys("New Discussion Title")
      f("label[for='use_for_grading']").click
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

    describe "checkpoints" do
      it "works if has_sub_assignments is true but missing sub_assignments" do
        Account.site_admin.enable_feature!(:react_discussions_post)
        @course.root_account.enable_feature!(:discussion_checkpoints)

        @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        @replies_required = 3

        @reply_to_topic_checkpoint = Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 3
        )
        @reply_to_entry_checkpint = Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 3.days.from_now }],
          points_possible: 9,
          replies_required: @replies_required
        )
        dt_assignment = @checkpointed_discussion.assignment

        dt_sub_assignments = @checkpointed_discussion.assignment.sub_assignments
        sub1 = dt_sub_assignments.first
        sub2 = dt_sub_assignments.last
        sub1.workflow_state = "deleted"
        sub1.save(validate: false)
        sub2.workflow_state = "deleted"
        sub2.save(validate: false)
        dt_assignment.reload
        dt_assignment.has_sub_assignments = true
        dt_assignment.save(validate: false)

        get "/courses/#{@course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"
        expect(f("#assignment_post_to_sis")).to be_enabled
      end
    end
  end

  it "does not display Sync to SIS option when feature not configured", priority: "1" do
    mock_feature_flag(:post_grades, false)
    get "/courses/#{@course.id}/discussion_topics/new"
    f("label[for='use_for_grading']").click
    expect(f("#content")).not_to contain_css("#assignment_post_to_sis")
  end

  shared_examples "gradebook_sync_grades" do
    before(:once) do
      plugin = Canvas::Plugin.find("grade_export")
      plugin_setting = PluginSetting.find_by(name: plugin.id)
      plugin_setting ||= PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
      plugin_setting.update(disabled: false)
    end

    before do
      if @enhanced_filters
        @course.enable_feature!(:enhanced_gradebook_filters)
      end
      @assignment = @course.assignments.create!(name: "assignment",
                                                assignment_group: @assignment_group,
                                                post_to_sis: true,
                                                workflow_state: "published")
    end

    def post_grades_dialog
      Gradebook.visit(@course)
      if @enhanced_filters
        Gradebook.select_sync
      else
        Gradebook.open_action_menu
      end
      expect(f("body")).to contain_css("[data-menu-id='post_grades_feature_tool']")
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

    it "asks for due dates in gradebook if due date is not given", priority: "1" do
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

describe "sync grades to sis" do
  it_behaves_like "sync grades to sis", true
  it_behaves_like "sync grades to sis", false
end
