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

require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')
require_relative '../feature_flag_helper'

describe "sync grades to sis" do
  include FeatureFlagHelper
  include_context "in-process server selenium tests"

  before :each do
    course_with_admin_logged_in
    mock_feature_flag(:post_grades, true)
    @course.sis_source_id = 'xyz'
    @course.save
    @assignment_group = @course.assignment_groups.create!(name: 'Assignment Group')
  end

  context "editing an existing topic with post_to_sis checked" do
    before :each do
      get "/courses/#{@course.id}/discussion_topics/new"
      f('#discussion-title').send_keys('New Discussion Title')
      f('#use_for_grading').click
      f('#assignment_post_to_sis').click
      wait_for_ajaximations
      click_option('#assignment_group_id', 'Assignment Group')
      wait_for_new_page_load { submit_form('.form-actions') }

      @discussion_topic = DiscussionTopic.last
    end

    it "should show post grades to sis box checked", priority: "1", test_id: 150520 do
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}/edit"
      expect(f('#assignment_post_to_sis')).to be_enabled
    end
  end

  it "does not display Sync to SIS option when feature not configured", priority: "1", test_id: 246614 do
    mock_feature_flag(:post_grades, false)
    get "/courses/#{@course.id}/discussion_topics/new"
    f('#use_for_grading').click
    expect(f("#content")).not_to contain_css('#assignment_post_to_sis')
  end

  context "gradebook_sync_grades" do
    before :each do
      @assignment = @course.assignments.create!(name: 'assignment', assignment_group: @assignment_group,
                                                post_to_sis: true)
    end

    def get_post_grades_dialog
      get "/courses/#{@course.id}/gradebook"
      expect(f('.post-grades-placeholder > button')).to be_displayed
      f('.post-grades-placeholder > button').click
      wait_for_ajaximations
      expect(f('.post-grades-dialog')).to be_displayed
    end

    it "should sync grades in a sync grades to SIS discussion", priority: "1", test_id: 150521 do
      @assignment.due_at = Time.zone.now.advance(days: 3)
      @course.discussion_topics.create!(user: @admin,
                                        title: 'Sync to SIS discussion',
                                        message: 'Discussion topic message',
                                        assignment: @assignment)
      get_post_grades_dialog
      expect(f('.assignments-to-post-count').text).to include("You are ready to sync 1 assignment")
    end

    it "should ask for due dates in gradebook if due date is not given", priority: "1", test_id: 244916 do
      @course.discussion_topics.create!(user: @admin,
                                        title: 'Sync to SIS discussion',
                                        message: 'Discussion topic message',
                                        assignment: @assignment)
      due_at = Time.zone.now + 3.days
      get_post_grades_dialog
      expect(f('#assignment-errors').text).to include("1 Assignment with Errors")
      f(".assignment-due-at").send_keys(format_date_for_view(due_at))
      f(' .form-dialog-content').click
      f('.form-controls button[type=button]').click
      expect(f('.assignments-to-post-count')).to include_text("You are ready to sync 1 assignment")
    end
  end
end
