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

require "spec_helper"

describe DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes do
  let(:course) { course_model }
  let(:assignment) { course.assignments.create!(submission_types: "online_text_entry", points_possible: 2) }

  context "fixes iframes with no data-media-id" do
    it "adds data-media-id" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      assignment.update! description: "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\"></iframe>"
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" data-media-id=\"#{Attachment.last.media_entry_id}\"></iframe>"
    end

    it "works for the intricate quiz data structures" do
      first_matching_attachment = Attachment.create! context: course, media_entry_id: "m-media_1", filename: "whatever", content_type: "audio/webm"
      second_matching_attachment = Attachment.create! context: course, media_entry_id: "m-media_2", filename: "whatever", content_type: "audio/mp3"
      third_matching_attachment = Attachment.create! context: course, media_entry_id: "m-media_3", filename: "whatever", content_type: "video/webm"

      quiz_description = "<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      question_text_1 = "<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      question_text_2 = "<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      question_text_3 = "<iframe src=\"/media_attachments_iframe/#{third_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      answer_text_1 = "<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      answer_text_2 = "<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      answer_text_3 = "<iframe src=\"/media_attachments_iframe/#{third_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      answer_text_4 = "<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      answer_text_5 = "<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      answer_text_6 = "<iframe src=\"/media_attachments_iframe/#{third_matching_attachment.id}\" data-media-type=\"video\"></iframe>"
      quiz_data = [
        {
          "question_text" => question_text_1,
          "answers" => [
            { "id" => "7427", "text" => answer_text_1, "comments" => "", "comments_html" => "", "weight" => 100.0 },
            { "id" => "3893", "text" => answer_text_2, "comments" => "", "comments_html" => "", "weight" => 0.0 }
          ],
        },
        {
          "question_text" => question_text_2,
          "answers" => [
            { "id" => "7427", "text" => answer_text_3, "comments" => "", "comments_html" => "", "weight" => 100.0 },
            { "id" => "3893", "text" => answer_text_4, "comments" => "", "comments_html" => "", "weight" => 0.0 }
          ],
        }
      ]
      q = course.quizzes.create!(description: quiz_description, quiz_data:)
      q.quiz_questions.create! question_data: {
        "question_text" => question_text_3,
        "answers" => [
          { "id" => "7427", "text" => answer_text_5, "comments" => "", "comments_html" => "", "weight" => 100.0 },
          { "id" => "3893", "text" => answer_text_6, "comments" => "", "comments_html" => "", "weight" => 0.0 }
        ],
      }
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      q.reload
      expect(q.description).to eq expected_body(first_matching_attachment.id, first_matching_attachment.media_entry_id)
      expect(q.quiz_data[0]["question_text"]).to eq expected_body(first_matching_attachment.id, first_matching_attachment.media_entry_id)
      expect(q.quiz_data[0]["answers"][0]["text"]).to eq expected_body(first_matching_attachment.id, first_matching_attachment.media_entry_id)
      expect(q.quiz_data[0]["answers"][1]["text"]).to eq expected_body(second_matching_attachment.id, second_matching_attachment.media_entry_id)
      expect(q.quiz_data[1]["question_text"]).to eq expected_body(second_matching_attachment.id, second_matching_attachment.media_entry_id)
      expect(q.quiz_data[1]["answers"][0]["text"]).to eq expected_body(third_matching_attachment.id, third_matching_attachment.media_entry_id)
      expect(q.quiz_data[1]["answers"][1]["text"]).to eq expected_body(first_matching_attachment.id, first_matching_attachment.media_entry_id)
      expect(q.quiz_questions.first.question_data["question_text"]).to eq expected_body(third_matching_attachment.id, third_matching_attachment.media_entry_id)
      expect(q.quiz_questions.first.question_data["answers"][0]["text"]).to eq expected_body(second_matching_attachment.id, second_matching_attachment.media_entry_id)
      expect(q.quiz_questions.first.question_data["answers"][1]["text"]).to eq expected_body(third_matching_attachment.id, third_matching_attachment.media_entry_id)
    end

    it "fixes all the possibly affected record types" do
      att = Attachment.create! context: course, filename: "whatever.flv", display_name: "whatever.flv", content_type: "video/avi"
      record_body = "<iframe src=\"/media_attachments_iframe/#{att.id}\" data-media-type=\"video\"></iframe>"
      another_course = course_model
      another_course.update! syllabus_body: record_body
      assignment = another_course.assignments.create!(description: record_body, submission_types: "online_text_entry", points_possible: 2)
      assessment_question_bank = another_course.assessment_question_banks.create!
      assessment_question = assessment_question_bank.assessment_questions.create! question_data: { "question_text" => record_body }
      discussion_topic = another_course.discussion_topics.create! message: record_body
      discussion_entry = discussion_topic.discussion_entries.create! message: record_body, user: User.create!
      quiz = Quizzes::Quiz.create! context: another_course
      quiz_question = quiz.quiz_questions.create! question_data: { "question_text" => record_body }
      wiki_page = another_course.wiki_pages.create! title: "Whatevs", body: record_body
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(another_course.reload.syllabus_body).to eq(expected_body(att.id, att.media_entry_id))
      expect(assignment.reload.description).to eq(expected_body(att.id, att.media_entry_id))
      expect(assessment_question.reload.question_data["question_text"]).to eq(expected_body(att.id, att.media_entry_id))
      expect(discussion_topic.reload.message).to eq(expected_body(att.id, att.media_entry_id))
      expect(discussion_entry.reload.message).to eq(expected_body(att.id, att.media_entry_id))
      expect(quiz_question.reload.question_data["question_text"]).to eq(expected_body(att.id, att.media_entry_id))
      expect(wiki_page.reload.body).to eq(expected_body(att.id, att.media_entry_id))
    end

    it "also adds display: inline-block to style" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      assignment.update! description: "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" style=\"width: 1364px; height: 767px;\"></iframe>"
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" style=\"width: 1364px; height: 767px; display: inline-block;\" data-media-id=\"#{Attachment.last.media_entry_id}\"></iframe>"
    end

    it "adds style properly even if it looks weird" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      assignment.update! description: "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" style=\"width: 1364px; height: 767px\"></iframe>"
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" style=\"width: 1364px; height: 767px; display: inline-block;\" data-media-id=\"#{Attachment.last.media_entry_id}\"></iframe>"
    end
  end

  context "leaves iframes alone" do
    it "if data-media-is is present" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      html = "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" data-media-id=\"#{Attachment.last.media_entry_id}\"></iframe>"
      assignment.update! description: html
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq html
    end

    it "if data-media-is is present even if wrong" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      html = "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" data-media-id=\"123456\"></iframe>"
      assignment.update! description: html
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq html
    end

    it "if the attachment id is bad" do
      Attachment.create! context: course, filename: "whatever.flv", display_name: "whatever.flv", content_type: "unknown/unknown"
      html = "<iframe src=\"/media_attachments_iframe/nonexistent\" data-media-type=\"unknown\"></iframe><iframe src=\"/files/#{Attachment.last.id}/download?\"></iframe>"
      assignment.update! description: html
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq html
    end

    it "if there is no data-media-type" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      html = "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\"></iframe>"
      assignment.update! description: html
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq html
    end

    it "does not alter style if it already has display" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      assignment.update! description: "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" style=\"display: none\"></iframe>"
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" style=\"display: none\" data-media-id=\"#{Attachment.last.media_entry_id}\"></iframe>"
    end

    it "does not add style if it is not present" do
      Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"
      assignment.update! description: "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\"></iframe>"
      DataFixup::AddMediaIdAndStyleDisplayAttributesToIframes.run
      expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\" data-media-type=\"unknown\" data-media-id=\"#{Attachment.last.media_entry_id}\"></iframe>"
    end
  end

  def expected_body(att_id, media_id)
    "<iframe src=\"/media_attachments_iframe/#{att_id}\" data-media-type=\"video\" data-media-id=\"#{media_id}\"></iframe>"
  end
end
