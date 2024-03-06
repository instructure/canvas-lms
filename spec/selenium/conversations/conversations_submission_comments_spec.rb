# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../helpers/conversations_common"
require_relative "../helpers/shared_examples_common"

describe "conversations new" do
  include_context "in-process server selenium tests"
  include SharedExamplesCommon
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, "active") }
    cat = @course.group_categories.create(name: "the groups")
    @group = cat.groups.create(name: "the group", context: @course)
    @group.users = [@s1, @s2]

    @course1 = @course
    @course1.name = "Course 1"
    @course1.save!
    @course2 = course_factory(active_course: true, course_name: "Course 2")
    teacher_in_course(user: @teacher, course: @course2, active_all: true)
    student_in_course(user: @s1, active_all: true, course: @course1)
    student_in_course(user: @s2, active_all: true, course: @course2)

    def assignment_with_submission_comments(title, student, course)
      assignment = course.assignments.create!(title:, description: "hai", points_possible: "14.2", submission_types: "online_text_entry")
      sub = assignment.grade_student(student, { grade: "12", grader: @teacher }).first
      sub.workflow_state = "submitted"
      sub.submission_comments.create!(comment: "c1", author: @teacher)
      sub.submission_comments.create!(comment: "c2", author: student)
      sub.save!
      sub
    end

    assignment_with_submission_comments("assignment 1", @s1, @course1)
    @submission = assignment_with_submission_comments("assignment 2", @s2, @course2)
  end

  # the js errors caught in here are captured by VICE-2507
  context "when react_inbox feature flag is on", :ignore_js_errors do
    before do
      Account.default.set_feature_flag! :react_inbox, "on"
    end

    it "has working course and address book filters" do
      get "/conversations"
      f("input[title='Inbox']").click
      fj("li:contains('Submission Comments')").click
      convos = ff("[data-testid='conversation']")

      expect(convos[0].text).to include  "Course 2 - assignment 2"
      expect(convos[1].text).to include  "Course 1 - assignment 1"
      wait_for_ajaximations
      f("input[placeholder='All Courses']").click
      wait_for_ajaximations
      fj("li:contains('Course 1')").click
      expect(ff("[data-testid='conversation']").count).to eq 1
      expect(f("[data-testid='conversation']").text).to include "Course 1 - assignment 1"

      f("[data-testid='delete-course-button']").click
      f("input[placeholder='Search...']").send_keys "second student"
      fj("li:contains('second student')").click
      expect(ff("[data-testid='conversation']").count).to eq 1
      expect(f("[data-testid='conversation']").text).to include "Course 2 - assignment 2"
    end

    it "can reply to submission comments" do
      get "/conversations"
      f("input[title='Inbox']").click
      fj("li:contains('Submission Comments')").click
      convos = ff("[data-testid='conversation']")
      convos[0].click
      wait_for_ajaximations
      f("button[data-testid='reply']").click
      f("textarea[data-testid='message-body']").send_keys("my submission comment reply")
      f("button[data-testid='send-button']").click
      wait_for_ajaximations
      # make sure compose modal is gone
      expect(f("body")).not_to contain_jqcss("textarea[data-testid='message-body']")
      expect(fj("span:contains('my submission comment reply')")).to be_present
      expect(SubmissionComment.last.comment).to eq "my submission comment reply"
    end
  end

  context "when react_inbox feature flag is off" do
    before do
      Account.default.set_feature_flag! :react_inbox, "off"
    end

    context "submission comment stream items" do
      before do
        conversations
        select_view("submission_comments")
      end

      describe "view filter" do
        it "shows submission comments", priority: "2" do
          expect(conversation_elements.size).to eq 2
        end

        it "filters by course", priority: "2" do
          select_course(@course1.id)
          expect(conversation_elements.size).to eq 1
        end

        it "filters by submitter", priority: "2" do
          name = @s2.name
          f("[role=main] header [role=search] input").send_keys(name)
          fj(".ac-result:contains('#{name}')").click
          expect(conversation_elements.length).to eq 1
        end
      end

      it "adds new messages to the view", priority: "2" do
        initial_message_count = @submission.submission_comments.count
        conversation_elements[0].click
        wait_for_ajaximations
        reply_to_submission_comment
        expect(ffj(".message-item-view").length).to eq(initial_message_count + 1)
        expect(@submission.reload.submission_comments.count).to eq(initial_message_count + 1)
      end

      it "marks unread on click", priority: "2" do
        expect(@submission.read?(@teacher)).to be_falsey
        conversation_elements[0].click
        wait_for_ajaximations
        expect(@submission.read?(@teacher)).to be_truthy
      end

      it "marks an read/unread", priority: "2" do
        expect(@submission.read?(@teacher)).to be_falsey
        toggle = fj(".read-state", conversation_elements[0])
        toggle.click
        wait_for_ajaximations
        expect(@submission.read?(@teacher)).to be_truthy
        toggle.click
        wait_for_ajaximations
        expect(@submission.read?(@teacher)).to be_falsey
      end

      shared_examples "shows submission comments" do |context|
        before do
          case context
          when :student
            user_session(@s2)
          when :teacher
            user_session(@teacher)
          end

          conversation_elements[0].click
        end

        it "shows submission comments in submissions page and inbox", priority: "2" do
          expect(@submission.submission_comments.count).to eq(2)
          expect(ff(".message-content > li").size).to eq(2)
        end

        it "shows only the reply button", priority: "2" do
          # make sure there is no cog menu
          expect(f(".message-detail-actions")).not_to contain_css(".inline-block")
          expect(f("#submission-reply-btn")).to be_present
        end

        it "shows replies in the submission comments", priority: "2" do
          reply_to_submission_comment
          expect(ffj(".message-item-view").length).to eq(3)
          expect(@submission.submission_comments.count).to eq(3)
        end
      end

      it_behaves_like "shows submission comments", :student
      it_behaves_like "shows submission comments", :teacher
    end
  end
end
