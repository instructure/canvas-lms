# frozen_string_literal: true

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

require_relative "messages_helper"

describe "submission_graded" do
  before :once do
    submission_model
  end

  let(:asset) { @submission }
  let(:notification_name) { :submission_graded }

  it_behaves_like "a message"

  it "includes the submission's submitter name if receiver is not the submitter and has the setting turned on" do
    observer = user_model
    message = generate_message(:submission_graded, :summary, asset, user: observer)
    expect(message.body).not_to match("For #{@submission.user.name}")

    observer.preferences[:send_observed_names_in_notifications] = true
    observer.save!
    message = generate_message(:submission_graded, :summary, asset, user: observer)
    expect(message.body).to match("For #{@submission.user.name}")
  end

  context "with a graded submission and sending scores in emails is allowed" do
    before do
      @assignment.points_possible = 100
      @assignment.save!
      @submission.score = 99
      @submission.workflow_state = "graded"
      @submission.save!
      @student.preferences[:send_scores_in_emails] = true
      @student.save!
    end

    it "shows score" do
      summary = generate_message(:submission_graded, :summary, asset, user: @student)
      expect(summary.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      email = generate_message(:submission_graded, :email, asset, user: @student)
      expect(email.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      expect(email.html_body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      sms = generate_message(:submission_graded, :sms, asset, user: @student)
      expect(sms.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
    end

    it "shows grade instead when user is quantitative data restricted" do
      course_root_account = @assignment.course.root_account
      # truthy feature flag
      course_root_account.enable_feature! :restrict_quantitative_data

      # truthy setting
      course_root_account.settings[:restrict_quantitative_data] = { value: true, locked: true }
      course_root_account.save!
      @assignment.course.restrict_quantitative_data = true
      @assignment.course.save!

      summary = generate_message(:submission_graded, :summary, asset, user: @student)
      expect(summary.body).to include("grade: A")
      email = generate_message(:submission_graded, :email, asset, user: @student)
      expect(email.body).to include("grade: A")
      expect(email.html_body).to include("grade: A")
      sms = generate_message(:submission_graded, :sms, asset, user: @student)
      expect(sms.body).to include("grade: A")
    end

    it "show which sub assignment was graded" do
      @course.account.enable_feature!(:discussion_checkpoints)
      @reply_to_topic, @reply_to_entry = graded_discussion_topic_with_checkpoints(context: @course)
      @reply_to_topic.submit_homework @student, body: "Test reply to topic for student"
      submission = @reply_to_topic.grade_student(@student, grade: 5, grader: @teacher).first

      email = generate_message(:submission_graded, :email, submission, user: @student)
      expect(email.body).to include("Reply To Topic")
      expect(email.html_body).to include("Reply To Topic")
      sms = generate_message(:submission_graded, :sms, submission, user: @student)
      expect(sms.body).to include("Reply To Topic")
    end

    it "uses parent assignment ID in URLs for discussion checkpoint submissions" do
      @course.account.enable_feature!(:discussion_checkpoints)
      @teacher = User.create!(name: "teacher")
      @course.enroll_teacher(@teacher)

      # Create a graded discussion with checkpoints
      discussion_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "Checkpointed Discussion")
      parent_assignment = discussion_topic.assignment

      # Create checkpoints
      reply_to_topic_checkpoint = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic:,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 1.day.from_now }],
        points_possible: 5
      )

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic:,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 2.days.from_now }],
        points_possible: 5,
        replies_required: 2
      )

      # Student submits to the checkpoint
      sub_assignment = reply_to_topic_checkpoint
      submission = sub_assignment.grade_student(@student, { grade: "4", grader: @teacher }).first
      submission.workflow_state = "submitted"
      submission.save!

      # Test all message formats
      email = generate_message(:submission_graded, :email, submission, user: @student)
      expect(email.url).to include("assignments/#{parent_assignment.id}")
      expect(email.url).not_to include("assignments/#{sub_assignment.id}")

      summary = generate_message(:submission_graded, :summary, submission, user: @student)
      expect(summary.url).to include("assignments/#{parent_assignment.id}")
      expect(summary.url).not_to include("assignments/#{sub_assignment.id}")
    end
  end
end
