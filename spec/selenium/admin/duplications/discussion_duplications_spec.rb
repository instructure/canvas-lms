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
#

require_relative "../../common"
require_relative "../../discussions/discussion_helpers"

describe "duplicate discussion" do
  include_context "in-process server selenium tests"
  include_context "discussions_page_shared_context"

  context "discussion created by teacher" do
    context "duplicating" do
      describe "course context" do
        before do
          course_with_teacher(active_all: true, name: "teacher1")
          @discussion_topic = DiscussionHelpers.create_discussion_topic(
            @course,
            @teacher,
            "Discussion 1 Title",
            "Discussion 1 message",
            nil
          )
          user_session(@teacher)
          get discussions_topic_page
        end

        it "has duplication option for discussions", priority: "2" do
          f(".discussions-index-manage-menu").click
          expect(f("#duplicate-discussion-menu-option")).to include_text("Duplicate")
        end
      end

      describe "group context" do
        # Don't bother testing students not in the group -- there should be
        # other specs elsewhere that mandate that such students can't even
        # see this page.
        before :once do
          course_with_teacher(active_all: true)
          student_in_course(active_all: true)
          @course.update(allow_student_discussion_editing: true,
                         allow_student_discussion_topics: true)
          @group_category = @course.group_categories.create!(name: "Group Category")
          @group = @course.groups.create!(group_category: @group_category, name: "Group 1")
          @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
          @group.add_user(@student, "accepted")
          @course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")
          @group.add_user(@teacher)
        end

        def group_discussion_index_url(group)
          "/groups/#{group.id}/discussion_topics"
        end

        it "has duplication option for group discussions page" do
          user_session(@teacher)
          DiscussionHelpers.create_discussion_topic(
            @group, @teacher, "Teacher Topic", "GroupDiscussionMessage", nil
          )
          get group_discussion_index_url(@group)
          f(".discussions-index-manage-menu").click
          wait_for_animations
          # Unlike with course discussions, there is an al-options classed menu
          # that allows us to change a group selection.  So we need to make sure
          # we're getting the options that allow us to select discussion actions
          expect(f("#duplicate-discussion-menu-option")).to include_text("Duplicate")
        end

        def create_topic_and_go_to_index_page(user, topic_title)
          @group.discussion_topics.create!(user:, title: topic_title, message: "blahblahblah")
          user_session(user)
          get group_discussion_index_url(@group)
        end

        it "teacher can duplicate a discussion" do
          create_topic_and_go_to_index_page(@teacher, "Teacher Topic")
          f(".discussions-index-manage-menu").click
          wait_for_animations
          f("#duplicate-discussion-menu-option").click
          wait_for_ajaximations
          expect(DiscussionTopic.last.title).to eq "Teacher Topic Copy"
        end

        it "student can duplicate a discussion if student editing enabled" do
          create_topic_and_go_to_index_page(@student, "Student Topic")
          f(".discussions-index-manage-menu").click
          wait_for_animations
          f("#duplicate-discussion-menu-option").click
          wait_for_ajaximations
          expect(DiscussionTopic.last.title).to eq "Student Topic Copy"
        end

        it "a teacher can duplicate a student's discussion" do
          @group.discussion_topics.create!(user: @student, title: "Student Topic", message: "blahblahblah")
          user_session(@teacher)
          get group_discussion_index_url(@group)
          f(".discussions-index-manage-menu").click
          wait_for_animations
          f("#duplicate-discussion-menu-option").click
          wait_for_ajaximations
          expect(DiscussionTopic.last.title).to eq "Student Topic Copy"
        end
      end
    end
  end
end
