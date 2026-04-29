# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::AddAttachmentAssociationsToAllAssets do
  before(:once) do
    @account = account_model
    @course = course_model(account: @account)
    @user = user_model
    @image = attachment_model(context: @course, filename: "test_image.png")
    @video = attachment_model(context: @course, filename: "test_video.mp4")
  end

  describe "AccountNotification" do
    it "creates attachment associations for files in message" do
      message = <<~HTML
        <p><img src="/accounts/#{@account.id}/files/#{@image.id}/preview"></p>
      HTML
      notification = @account.announcements.build(
        subject: "Important",
        message:,
        start_at: Time.zone.now,
        end_at: 1.day.from_now
      )
      notification.user = @user
      notification.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: notification).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end
  end

  describe "Assignment" do
    it "creates attachment associations for files in description" do
      assignment = @course.assignments.build(
        description: <<~HTML
          <p>
            <iframe src="/media_attachments_iframe/#{@video.id}?type=video" data-media-type="video"></iframe>
            <img src="/courses/#{@course.id}/files/#{@image.id}/preview" alt="test">
          </p>
        HTML
      )
      assignment.updating_user = @user
      assignment.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: assignment).count).to eq 2
      expect(AttachmentAssociation.pluck(:attachment_id)).to match_array([@image.id, @video.id])
      expect(AttachmentAssociation.distinct.pluck(:context_id)).to eq([assignment.id])
    end
  end

  describe "CalendarEvent" do
    it "creates attachment associations for files in description" do
      event = @course.calendar_events.build(
        title: "Test Event",
        start_at: Time.zone.now,
        description: <<~HTML
          <iframe src="/media_attachments_iframe/#{@video.id}"></iframe>
        HTML
      )
      event.updating_user = @user
      event.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: event).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @video.id
    end

    it "creates attachment associations for series heads and copies to children" do
      series_uuid = SecureRandom.uuid

      description = <<~HTML
        <p><img src="/courses/#{@course.id}/files/#{@image.id}/preview"></p>
        <iframe src="/media_attachments_iframe/#{@video.id}"></iframe>
      HTML

      series_head = @course.calendar_events.build(
        title: "Recurring Event",
        start_at: Time.zone.now,
        description:,
        series_uuid:,
        series_head: true
      )
      series_head.updating_user = @user
      series_head.save!

      child1 = @course.calendar_events.build(
        title: "Recurring Event",
        start_at: 1.week.from_now,
        description: series_head.description,
        series_uuid:,
        series_head: false
      )
      child1.updating_user = @user
      child1.save!

      child2 = @course.calendar_events.build(
        title: "Recurring Event",
        start_at: 2.weeks.from_now,
        description: series_head.description,
        series_uuid:,
        series_head: false
      )
      child2.updating_user = @user
      child2.save!

      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: series_head).count).to eq 2
      expect(AttachmentAssociation.where(context: series_head).pluck(:attachment_id)).to match_array([@image.id, @video.id])

      expect(AttachmentAssociation.where(context: child1).count).to eq 2
      expect(AttachmentAssociation.where(context: child1).pluck(:attachment_id)).to match_array([@image.id, @video.id])

      expect(AttachmentAssociation.where(context: child2).count).to eq 2
      expect(AttachmentAssociation.where(context: child2).pluck(:attachment_id)).to match_array([@image.id, @video.id])
    end

    it "processes child events with different descriptions from series head" do
      series_uuid = SecureRandom.uuid

      series_head = @course.calendar_events.build(
        title: "Recurring Event",
        start_at: Time.zone.now,
        description: "No files here",
        series_uuid:,
        series_head: true
      )
      series_head.updating_user = @user
      series_head.save!

      child = @course.calendar_events.build(
        title: "Recurring Event",
        start_at: 1.week.from_now,
        description: "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">",
        series_uuid:,
        series_head: false
      )
      child.updating_user = @user
      child.save!

      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: child).count).to eq 1
      expect(AttachmentAssociation.where(context: child).first.attachment_id).to eq @image.id
    end
  end

  describe "DiscussionEntry" do
    it "creates attachment associations for files in message" do
      topic = @course.discussion_topics.create!(title: "Topic", message: "Message", user: @user)
      entry = topic.discussion_entries.build(
        user: @user,
        message: <<~HTML
          <iframe src="/media_attachments_iframe/#{@video.id}"></iframe>
        HTML
      )
      entry.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: entry).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @video.id
    end
  end

  describe "DiscussionTopic" do
    it "creates attachment associations for files in message" do
      topic = @course.discussion_topics.build(
        title: "Test Topic",
        message: <<~HTML
          <p><img src="/courses/#{@course.id}/files/#{@image.id}/preview"></p>
        HTML
      )
      topic.user = @user
      topic.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: topic).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end

    it "does not process group discussion child topics (they are filtered by root_topic_id)" do
      group_category = @course.group_categories.create!(name: "Project Groups")
      group = group_category.groups.create!(name: "Group 1", context: @course)

      root_topic = @course.discussion_topics.build(
        title: "Group Discussion",
        message: <<~HTML
          <p><img src="/courses/#{@course.id}/files/#{@image.id}/preview"></p>
        HTML
      )
      root_topic.user = @user
      root_topic.save!

      child_topic = group.discussion_topics.build(
        title: "Group Discussion",
        message: root_topic.message,
        root_topic_id: root_topic.id
      )
      child_topic.user = @user
      child_topic.save!

      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: root_topic).count).to eq 1
      # child topic has 0 because we filter by root_topic_id: nil in the data fixup
      # child topics get associations when they're created, not from this fixup
      expect(AttachmentAssociation.where(context: child_topic).count).to eq 0
    end

    it "processes child topics with different messages separately" do
      group_category = @course.group_categories.create!(name: "Project Groups")
      group = group_category.groups.create!(name: "Group 1", context: @course)

      group_image = attachment_model(context: group, filename: "group_image.png")

      root_topic = @course.discussion_topics.build(
        title: "Group Discussion",
        message: "No files in root"
      )
      root_topic.user = @user
      root_topic.save!

      message = <<~HTML
        <p><img src="/groups/#{group.id}/files/#{group_image.id}/preview"></p>
      HTML

      child_topic = group.discussion_topics.build(
        title: "Group Discussion",
        message:,
        root_topic_id: root_topic.id
      )
      child_topic.user = @user
      child_topic.save!

      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      # Root topic has no files, so no associations
      expect(AttachmentAssociation.where(context: root_topic).count).to eq 0
      # Child topic has different message with file link, so it should be processed
      expect(AttachmentAssociation.where(context: child_topic).count).to eq 1
    end
  end

  describe "LearningOutcome" do
    it "creates attachment associations for files in description" do
      outcome = @course.created_learning_outcomes.build(
        short_description: "Test Outcome",
        description: <<~HTML
          <p><img src="/courses/#{@course.id}/files/#{@image.id}/preview"></p>
        HTML
      )
      outcome.updating_user = @user
      outcome.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: outcome).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end
  end

  describe "LearningOutcomeGroup" do
    it "creates attachment associations for files in description" do
      group = @course.learning_outcome_groups.build(
        title: "Test Group",
        description: <<~HTML
          <iframe src="/media_attachments_iframe/#{@video.id}"></iframe>
        HTML
      )
      group.updating_user = @user
      group.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: group).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @video.id
    end
  end

  describe "Quizzes::Quiz" do
    it "creates attachment associations for files in description" do
      quiz = @course.quizzes.build(
        title: "Test Quiz",
        description: <<~HTML
          <p><img src="/courses/#{@course.id}/files/#{@image.id}/preview"></p>
        HTML
      )
      quiz.updating_user = @user
      quiz.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: quiz).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end
  end

  describe "Quizzes::QuizQuestion" do
    it "creates attachment associations for files in question_text" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      question = quiz.quiz_questions.create!
      question.question_data = {
        "question_text" => "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">"
      }
      question.updating_user = @user
      question.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: question).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end

    it "creates attachment associations for files in correct_comments_html" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      question = quiz.quiz_questions.create!
      question.question_data = {
        "correct_comments_html" => "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">"
      }
      question.updating_user = @user
      question.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: question).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end

    it "creates attachment associations for files in incorrect_comments_html" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      question = quiz.quiz_questions.create!
      question.question_data = {
        "incorrect_comments_html" => "<iframe src=\"/media_attachments_iframe/#{@video.id}\"></iframe>"
      }
      question.updating_user = @user
      question.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: question).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @video.id
    end

    it "creates attachment associations for files in neutral_comments_html" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      question = quiz.quiz_questions.create!
      question.question_data = {
        "neutral_comments_html" => "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">"
      }
      question.updating_user = @user
      question.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: question).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end

    it "creates attachment associations for files across multiple fields" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      question = quiz.quiz_questions.create!
      question.question_data = {
        "question_text" => "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">",
        "correct_comments_html" => "<iframe src=\"/media_attachments_iframe/#{@video.id}\"></iframe>"
      }
      question.updating_user = @user
      question.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: question).count).to eq 2
      expect(AttachmentAssociation.pluck(:attachment_id)).to match_array([@image.id, @video.id])
    end
  end

  describe "Quizzes::QuizSubmission" do
    it "creates attachment associations for files in essay question submissions" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      quiz.quiz_questions.create!(
        question_data: {
          name: "Essay Question",
          question_type: "essay_question",
          question_text: "Write an essay"
        }
      )
      quiz.quiz_questions.create!(
        question_data: {
          name: "Another Essay",
          question_type: "essay_question",
          question_text: "Write another essay"
        }
      )
      quiz.generate_quiz_data
      quiz.save!

      @course.enroll_student(@user, enrollment_state: "active")
      submission = quiz.generate_submission(@user)
      submission.submission_data = [
        {
          question_id: quiz.quiz_data[0][:id],
          text: "<p>Here is my essay with an image: <img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\"></p>"
        },
        {
          question_id: quiz.quiz_data[1][:id],
          text: "<p>My other essay with a video: <iframe src=\"/media_attachments_iframe/#{@video.id}\"></iframe></p>"
        }
      ]
      submission.workflow_state = "complete"
      submission.updating_user = @user
      submission.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: submission).count).to eq 2
      expect(AttachmentAssociation.pluck(:attachment_id)).to match_array([@image.id, @video.id])
    end

    it "handles quiz submissions without essay questions" do
      quiz = @course.quizzes.create!(title: "Test Quiz")
      quiz.quiz_questions.create!(
        question_data: {
          name: "Multiple Choice",
          question_type: "multiple_choice_question",
          question_text: "Pick one"
        }
      )
      quiz.generate_quiz_data
      quiz.save!

      @course.enroll_student(@user, enrollment_state: "active")
      submission = quiz.generate_submission(@user)
      submission.submission_data = [
        {
          question_id: quiz.quiz_data[0][:id],
          answer_id: 123
        }
      ]
      submission.workflow_state = "complete"
      submission.save!

      expect do
        DataFixup::AddAttachmentAssociationsToAllAssets.run
      end.not_to raise_error
    end
  end

  describe "Submission" do
    it "creates attachment associations for files in body" do
      assignment = @course.assignments.create!(submission_types: "online_text_entry")
      @course.enroll_student(@user, enrollment_state: "active")
      submission = assignment.submit_homework(
        @user,
        submission_type: "online_text_entry",
        body: <<~HTML
          <p><iframe src="/media_attachments_iframe/#{@video.id}"></iframe></p>
        HTML
      )
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: submission).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @video.id
    end
  end

  describe "TermsOfServiceContent" do
    it "creates attachment associations for files in content" do
      tos = TermsOfServiceContent.new(
        account: @account,
        content: <<~HTML
          <p><img src="/accounts/#{@account.id}/files/#{@image.id}/preview"></p>
        HTML
      )
      tos.updating_user = @user
      tos.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: tos).count).to eq 1
      expect(AttachmentAssociation.first.attachment_id).to eq @image.id
    end
  end

  describe "WikiPage" do
    it "creates attachment associations for files in body" do
      page = @course.wiki_pages.build(
        title: "Test Page",
        body: <<~HTML
          <p>
            <img src="/courses/#{@course.id}/files/#{@image.id}/preview">
            <iframe src="/media_attachments_iframe/#{@video.id}"></iframe>
          </p>
        HTML
      )
      page.user = @user
      page.save!
      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: page).count).to eq 2
      expect(AttachmentAssociation.pluck(:attachment_id)).to match_array([@image.id, @video.id])
    end
  end

  describe "existing associations" do
    it "does not recreate attachment associations that already exist" do
      assignment = @course.assignments.build(
        description: "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">"
      )
      assignment.updating_user = @user
      assignment.save!

      existing = @image.attachment_associations.create!(
        context: assignment,
        user: @user
      )

      expect do
        DataFixup::AddAttachmentAssociationsToAllAssets.run
      end.not_to change { AttachmentAssociation.count }

      expect(AttachmentAssociation.first.id).to eq existing.id
    end
  end

  describe "multiple models" do
    it "processes all model types in a single run" do
      assignment = @course.assignments.build(
        description: "<img src=\"/courses/#{@course.id}/files/#{@image.id}/preview\">"
      )
      assignment.updating_user = @user
      assignment.save!

      page = @course.wiki_pages.build(
        title: "Page",
        body: "<iframe src=\"/media_attachments_iframe/#{@video.id}\"></iframe>"
      )
      page.user = @user
      page.save!

      AttachmentAssociation.destroy_all

      DataFixup::AddAttachmentAssociationsToAllAssets.run

      expect(AttachmentAssociation.where(context: assignment).count).to eq 1
      expect(AttachmentAssociation.where(context: page).count).to eq 1
      expect(AttachmentAssociation.count).to eq 2
    end
  end
end
