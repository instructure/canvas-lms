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

require_relative "messages_helper"

describe "submission_comment" do
  include MessagesCommon

  before :once do
    submission_model
    @comment = @submission.add_comment(comment: "new comment")
  end

  let(:notification_name) { :submission_comment }
  let(:asset) { @comment }
  let(:anonymous_user) { "Anonymous User" }

  context "anonymous peer disabled" do
    describe ".email" do
      let(:path_type) { :email }

      it "renders" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).not_to include(anonymous_user)
      end

      it "nevers render reply to footer" do
        IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
        msg = generate_message(notification_name, path_type, asset)
        expect(msg.body.include?("by responding to this message")).to be false
      end
    end

    describe ".sms" do
      let(:path_type) { :sms }

      it "renders" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).not_to include(anonymous_user)
      end
    end

    describe ".summary" do
      let(:path_type) { :summary }

      it "renders" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).not_to include(anonymous_user)
      end
    end
  end

  context "anonymous peer enabled" do
    before :once do
      @submission.assignment.update_attribute(:anonymous_peer_reviews, true)
      @comment.reload
    end

    describe ".email" do
      let(:path_type) { :email }

      it "shows anonymous when anonymous peer review enabled" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include(anonymous_user)
      end
    end

    describe ".sms" do
      let(:path_type) { :sms }

      it "shows anonymous when anonymous peer review enabled" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include(anonymous_user)
      end
    end

    describe ".summary" do
      let(:path_type) { :summary }

      it "shows anonymous when anonymous peer review enabled" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include(anonymous_user)
      end
    end
  end

  context "discussion checkpoint submissions" do
    before :once do
      @course.account.enable_feature!(:discussion_checkpoints)
      @teacher = User.create!(name: "teacher")
      @course.enroll_teacher(@teacher)

      # Create a graded discussion with checkpoints
      @discussion_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "Checkpointed Discussion")
      @parent_assignment = @discussion_topic.assignment

      # Create checkpoints
      @reply_to_topic_checkpoint = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @discussion_topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 1.day.from_now }],
        points_possible: 5
      )

      # Student submits to the checkpoint
      @checkpoint_submission = @reply_to_topic_checkpoint.grade_student(@student, { grade: "4", grader: @teacher }).first
      @checkpoint_submission.workflow_state = "submitted"
      @checkpoint_submission.save!

      @checkpoint_comment = @checkpoint_submission.add_comment(comment: "Great work on the checkpoint!")
    end

    it "uses parent assignment ID in URLs for email notifications" do
      email = generate_message(:submission_comment, :email, @checkpoint_comment, user: @student)
      expect(email.url).to include("assignments/#{@parent_assignment.id}")
      expect(email.url).not_to include("assignments/#{@reply_to_topic_checkpoint.id}")
    end

    it "uses parent assignment ID in URLs for summary notifications" do
      summary = generate_message(:submission_comment, :summary, @checkpoint_comment, user: @student)
      expect(summary.url).to include("assignments/#{@parent_assignment.id}")
      expect(summary.url).not_to include("assignments/#{@reply_to_topic_checkpoint.id}")
    end
  end
end
