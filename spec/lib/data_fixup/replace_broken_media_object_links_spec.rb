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

describe DataFixup::ReplaceBrokenMediaObjectLinks do
  let(:course) { course_model }

  context "bad link types" do
    let(:assignment) { course.assignments.create!(submission_types: "online_text_entry", points_possible: 2) }

    it "fixes bad links with data-media-id" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      assignment.update(description: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(assignment.description).to eq fixed_html
    end

    it "fixes bad links with media_object/media_id" do
      broken_html = <<-HTML.strip
        <iframe style="width: 320px; height: 14.25rem; display: inline-block;" title="title" data-media-type="audio" src="https://url.instructure.com/courses/1/file_contents/course%20files/media_objects/m-media.mp4" data-media-id="m-media"></iframe>
      HTML

      assignment.update(description: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 320px; height: 14.25rem; display: inline-block;" title="title" data-media-type="audio" src="https://url.instructure.com/media_objects_iframe/m-media" data-media-id="m-media"></iframe>
      HTML

      expect(assignment.description).to eq fixed_html
    end

    it "fixes bad links with media_object_iframe/media_id" do
      broken_html = <<-HTML.strip
        <iframe style="width: 599px; height: 337px; display: inline-block;" title="title" data-media-type="video" src="https://url.instructure.com/courses/1/file_contents/course%20files/media_objects_iframe/m-media?type=video?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="undefined"></iframe>
      HTML

      assignment.update(description: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 599px; height: 337px; display: inline-block;" title="title" data-media-type="video" src="https://url.instructure.com/media_objects_iframe/m-media?type=video?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="undefined"></iframe>
      HTML

      expect(assignment.description).to eq fixed_html
    end

    it "fixes bad links with media_comment" do
      broken_html = <<-HTML.strip
        <iframe id="media_comment_m-media" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="" data-media-type="video" src="https://url.instructure.com/courses/1/file_contents/course%20files/media_objects/m-media.mp4" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      assignment.update(description: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      fixed_html = <<-HTML.strip
        <iframe id="media_comment_m-media" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="" data-media-type="video" src="https://url.instructure.com/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(assignment.description).to eq fixed_html
    end

    it "doesn't update objects with similar types of bad links" do
      broken_html = <<-HTML.strip
        <a class="instructure_file_link instructure_scribd_file" title="title.docx" href="/courses/1/file_contents/course%20files/test.docx?canvas_download=1&amp;canvas_qs_wrap=1" data-api-returntype="File">Text</a>
        <img src="/courses/1/file_contents/course%20files/Syllabus/title.jpg" alt="alt text">
      HTML

      assignment.update(description: broken_html)
      updated_at = assignment.updated_at

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      expect(assignment.updated_at).to eq updated_at
    end

    it "doesn't update objects with iframes with unrecoverable bad links" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen"/>
        <a href="/courses/1/file_contents/course%20files/unfiled/title">Text</a>
      HTML

      assignment.update(description: broken_html)
      updated_at = assignment.updated_at

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      expect(assignment.updated_at).to eq updated_at
    end

    it "create CSV report of changes" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      assignment.update(description: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      assignment.reload

      broken_csv_html = <<-HTML.strip
        "<iframe style=""width: 400px; height: 225px; display: inline-block;"" title=""title"" data-media-type=""video"" src=""/courses/1/file_contents/course%20files/unfiled/title"" allowfullscreen=""allowfullscreen"" allow=""fullscreen"" data-media-id=""m-media""></iframe>"
      HTML

      fixed_csv_html = <<-HTML.strip
        "<iframe style=""width: 400px; height: 225px; display: inline-block;"" title=""title"" data-media-type=""video"" src=""/media_objects_iframe/m-media"" allowfullscreen=""allowfullscreen"" allow=""fullscreen"" data-media-id=""m-media""></iframe>"
      HTML

      att = Attachment.find_by("filename like 'data_fixup_replace_broken_media_object_links_#{Shard.current.id}_assignments_description_#{assignment.id}_#{assignment.id}%'")
      expect(File.read(att.open).strip).to eq("#{Shard.current.id},assignments,#{assignment.id},#{broken_csv_html},#{fixed_csv_html}")
    end
  end

  context "all models" do
    it "fixes bad links in assessment question" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      assessment_question_bank_model(course:)
      question_data = { question_text: broken_html }
      aq = assessment_question_model(bank: @bank, question_data:)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      aq.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(aq.question_data["question_text"]).to eq fixed_html
    end

    it "fixes bad links in course syllabus" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      course.update(syllabus_body: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      course.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(course.syllabus_body).to eq fixed_html
    end

    it "fixes bad links in discussion topic message" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      discussion_topic_model(context: course, message: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      @topic.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(@topic.message).to eq fixed_html
    end

    it "fixes bad links in quiz description" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      quiz_model(course:, description: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      @quiz.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(@quiz.description).to eq fixed_html
    end

    it "fixes bad links in quiz quiz_data" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      quiz_model(course:)
      quiz_data = test_quiz_data
      quiz_data.first[:question_text] = broken_html
      @quiz.update(quiz_data:)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      @quiz.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(@quiz.quiz_data.first["question_text"]).to eq fixed_html
    end

    it "fixes bad links in quiz question" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      quiz_model(course:)
      qq = @quiz.quiz_questions.create!(question_data: multiple_choice_question_data.merge("question_text" => broken_html))

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      qq.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(qq.question_data["question_text"]).to eq fixed_html
    end

    it "fixes bad links in wiki page body" do
      broken_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/courses/1/file_contents/course%20files/unfiled/title" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      wiki_page_model(course:, body: broken_html)

      DataFixup::ReplaceBrokenMediaObjectLinks.run
      @page.reload

      fixed_html = <<-HTML.strip
        <iframe style="width: 400px; height: 225px; display: inline-block;" title="title" data-media-type="video" src="/media_objects_iframe/m-media" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-media"></iframe>
      HTML

      expect(@page.body).to eq fixed_html
    end
  end
end
