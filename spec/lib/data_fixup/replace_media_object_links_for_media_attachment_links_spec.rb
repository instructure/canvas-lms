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

describe DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks do
  let(:course) { course_model }
  let(:assignment) { course.assignments.create!(submission_types: "online_text_entry", points_possible: 2) }

  context "using media object dimensions in iframe" do
    it "does not overwrite preexisting iframe dimensions" do
      MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", data: { extensions: { mp4: { width: 640, height: 400 } } }
      assignment.update! description: '<iframe width=0 height=0 src="/media_objects_iframe/m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW/?type=video&amp;embedded=true"></iframe>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(assignment.reload.description).to eq "<iframe width=\"0\" height=\"0\" src=\"/media_attachments_iframe/#{Attachment.last.id}/?type=video&amp;embedded=true\" style=\"width:640px; height:400px; \"></iframe>"
    end

    it "does not lose preexisting style settings" do
      MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", data: { extensions: { mp4: { width: 640, height: 400 } } }
      assignment.update! description: '<iframe width=0 height=0 src="/media_objects_iframe/m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW/?type=video&amp;embedded=true" style="background:#ffffff"></iframe>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(assignment.reload.description).to eq "<iframe width=\"0\" height=\"0\" src=\"/media_attachments_iframe/#{Attachment.last.id}/?type=video&amp;embedded=true\" style=\"width:640px; height:400px; background:#ffffff\"></iframe>"
    end

    it "does not overwrite preexisting dimension style settings" do
      MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", data: { extensions: { mp4: { width: 640, height: 400 } } }
      assignment.update! description: '<iframe width=0 height=0 src="/media_objects_iframe/m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW/?type=video&amp;embedded=true" style="width:0px; height:0px"></iframe>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(assignment.reload.description).to eq "<iframe width=\"0\" height=\"0\" src=\"/media_attachments_iframe/#{Attachment.last.id}/?type=video&amp;embedded=true\" style=\"width:0px; height:0px\"></iframe>"
    end

    it "places the dimensions in their own attributes and styles properly" do
      MediaObject.create! media_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", data: { extensions: { mp4: { width: 640, height: 400 } } }
      assignment.update! description: '<iframe src="/media_objects_iframe/m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW/?type=video&amp;embedded=true"></iframe>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}/?type=video&amp;embedded=true\" style=\"width:640px; height:400px; \"></iframe>"
    end
  end

  context "having to create attachments" do
    # it "replaces random links" do
    #   assignment.update! description: '<a href="/media_objects/media_id/info">clickme</a>'
    #   DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
    #   expect(Assignment.last.description).to eq "<iframe src=\"/media_attachments/#{Attachment.last.id}/info\"></iframe>"
    #   expect(Attachment.last.context).to eq assignment.context
    # end

    it "replaces media object iframes" do
      assignment.update! description: '<iframe src="/media_objects_iframe/m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW/?type=video&amp;embedded=true"></iframe>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(Assignment.last.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}/?type=video&amp;embedded=true\"></iframe>"
      expect(Attachment.last.context).to eq assignment.context
    end

    it "replaces media comments" do
      assignment.update! description: '<a id="media_comment_m-4uoGqVdEqXhpqu2ZMytHSy9XMV73aQ7E" class="instructure_inline_media_comment video_comment" data-media_comment_type="video" data-alt=""></a>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(Assignment.last.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\"></iframe>"
      expect(Attachment.last.context).to eq assignment.context
    end

    it "knows to ignore media attachments not context matched" do
      non_matching_attachment = Attachment.create! context: Course.create!, media_entry_id: "m-4uoGqVdEqXhpqu2ZMytHSy9XMV73aQ7E", filename: "whatever", content_type: "unknown/unknown"
      assignment.update! description: '<a id="media_comment_m-4uoGqVdEqXhpqu2ZMytHSy9XMV73aQ7E" class="instructure_inline_media_comment video_comment" data-media_comment_type="video" data-alt=""></a>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(Assignment.last.description).not_to eq "<iframe src=\"/media_attachments_iframe/#{non_matching_attachment.id}\"></iframe>"
      expect(Assignment.last.description).to eq "<iframe src=\"/media_attachments_iframe/#{Attachment.last.id}\"></iframe>"
      expect(Attachment.last.context).to eq assignment.context
    end
  end

  context "picking up preexisting attachments" do
    # it "replaces random links" do
    #   matching_attachment = Attachment.create! context: course, media_entry_id: "media_id", filename: "whatever", content_type: "unknown/unknown"
    #   assignment.update! description: '<a href="/media_objects/media_id/info">clickme</a>'
    #   page = course.wiki_pages.create!(title: ".-.", body: '<a href="http://fullthing/media_objects/media_id/info">clickme</a>')
    #   DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
    #   expect(assignment.reload.description).to eq "<iframe src=\"/media_attachments/#{matching_attachment.id}/info\"></iframe>"
    #   expect(page.reload.body).to eq "<iframe src=\"http://fullthing/media_attachments/#{matching_attachment.id}/info\"></iframe>"
    #   expect(Attachment.last.context).to eq assignment.context
    # end

    it "replaces media object iframes" do
      matching_attachment = Attachment.create! context: course, media_entry_id: "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW", filename: "whatever", content_type: "unknown/unknown"
      assignment.update! description: '<iframe src="/media_objects_iframe/m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW/?type=video&amp;embedded=true"></iframe>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(Assignment.last.description).to eq "<iframe src=\"/media_attachments_iframe/#{matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>"
      expect(matching_attachment.context).to eq assignment.context
    end

    it "replaces media comments" do
      matching_attachment = Attachment.create! context: course, media_entry_id: "m-4uoGqVdEqXhpqu2ZMytHSy9XMV73aQ7E", filename: "whatever", content_type: "unknown/unknown"
      assignment.update! description: '<a id="media_comment_m-4uoGqVdEqXhpqu2ZMytHSy9XMV73aQ7E" class="instructure_inline_media_comment video_comment" data-media_comment_type="video" data-alt=""></a>'
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(Assignment.last.description).to eq "<iframe src=\"/media_attachments_iframe/#{matching_attachment.id}\"></iframe>"
      expect(matching_attachment.context).to eq assignment.context
    end
  end

  def expected_body(context)
    att = context.attachments.last
    return "<iframe src=\"/media_attachments_iframe/#{att.id}/?verifier=#{att.uuid}&amp;type=video&amp;embedded=true\"></iframe>" if att.context.is_a?(User)

    "<iframe src=\"/media_attachments_iframe/#{att.id}/?type=video&amp;embedded=true\"></iframe>"
  end

  context "context matching to pre existing attachments" do
    it "chooses the proper attachments and rejects unmatching context ones" do
      media_id = "m-3EtLMkFf9KBMneRZozuhGmYGTJSiqELW"
      record_body = "<iframe src=\"/media_objects_iframe/#{media_id}/?type=video&amp;embedded=true\"></iframe>"
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
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      expect(another_course.reload.syllabus_body).to eq(expected_body(another_course))
      expect(assignment.reload.description).to eq(expected_body(assignment.context))
      expect(assessment_question.reload.question_data["question_text"]).to eq(expected_body(assessment_question))
      expect(discussion_topic.reload.message).to eq(expected_body(another_course))
      expect(discussion_entry.reload.message).to eq(expected_body(discussion_entry.user))
      expect(quiz_question.reload.question_data["question_text"]).to eq(expected_body(another_course))
      expect(wiki_page.reload.body).to eq(expected_body(wiki_page.context))
    end
  end

  context "with multiple media uses in content quiz" do
    it "replaces all the old media links throughout the data" do
      first_matching_attachment = Attachment.create! context: course, media_entry_id: "m-media_1", filename: "whatever", content_type: "unknown/unknown"
      second_matching_attachment = Attachment.create! context: course, media_entry_id: "m-media_2", filename: "whatever", content_type: "unknown/unknown"
      third_matching_attachment = Attachment.create! context: course, media_entry_id: "m-media_3", filename: "whatever", content_type: "unknown/unknown"

      quiz_description = "<iframe src=\"/media_objects_iframe/m-media_2/?type=video&amp;embedded=true\"></iframe>"
      question_text_1 = "<a id=\"media_comment_m-media_3\" class=\"instructure_inline_media_comment video_comment\" data-media_comment_type=\"video\" data-alt=''></a>"
      question_text_2 = "<a id=\"media_comment_m-media_2\" class=\"instructure_inline_media_comment video_comment\" data-media_comment_type=\"video\" data-alt=''></a>"
      question_text_3 = "<a id=\"media_comment_m-media_1\" class=\"instructure_inline_media_comment video_comment\" data-media_comment_type=\"video\" data-alt=''></a>"
      answer_text_1 = "<iframe src=\"/media_objects_iframe/m-media_1/?type=video&amp;embedded=true\"></iframe>"
      answer_text_2 = "<iframe src=\"/media_objects_iframe/m-media_2/?type=video&amp;embedded=true\"></iframe>"
      answer_text_3 = "<iframe src=\"/media_objects_iframe/m-media_3/?type=video&amp;embedded=true\"></iframe>"
      answer_text_4 = "<iframe src=\"/media_objects_iframe/m-media_1/?type=video&amp;embedded=true\"></iframe>"
      answer_text_5 = "<iframe src=\"/media_objects_iframe/m-media_2/?type=video&amp;embedded=true\"></iframe>"
      answer_text_6 = "<iframe src=\"/media_objects_iframe/m-media_3/?type=video&amp;embedded=true\"></iframe>"
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
      DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks.run
      q.reload
      expect(q.description).to eq("<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      expect(q.quiz_data[0]["question_text"]).to eq("<iframe src=\"/media_attachments_iframe/#{third_matching_attachment.id}\"></iframe>")
      expect(q.quiz_data[0]["answers"][0]["text"]).to eq("<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      expect(q.quiz_data[0]["answers"][1]["text"]).to eq("<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      expect(q.quiz_data[1]["question_text"]).to eq("<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}\"></iframe>")
      expect(q.quiz_data[1]["answers"][0]["text"]).to eq("<iframe src=\"/media_attachments_iframe/#{third_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      expect(q.quiz_data[1]["answers"][1]["text"]).to eq("<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      expect(q.quiz_questions.first.question_data["question_text"]).to eq("<iframe src=\"/media_attachments_iframe/#{first_matching_attachment.id}\"></iframe>")
      expect(q.quiz_questions.first.question_data["answers"][0]["text"]).to eq("<iframe src=\"/media_attachments_iframe/#{second_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
      expect(q.quiz_questions.first.question_data["answers"][1]["text"]).to eq("<iframe src=\"/media_attachments_iframe/#{third_matching_attachment.id}/?type=video&amp;embedded=true\"></iframe>")
    end
  end
end
