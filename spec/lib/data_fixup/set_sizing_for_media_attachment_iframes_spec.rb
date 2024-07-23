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

describe DataFixup::SetSizingForMediaAttachmentIframes do
  let(:course) { course_model }
  let(:assignment) { course.assignments.create!(submission_types: "online_text_entry", points_possible: 2) }

  it "fixes the precise broken style caused by the old datafix in other active records" do
    assignment.update! description: '<iframe style="width: px; height: px; float: left" src="/media_attachments_iframe/doesntmatter"></iframe>'
    DataFixup::SetSizingForMediaAttachmentIframes.run
    expect(assignment.reload.description).to eq '<iframe style="width: 320px; height: 14.25rem; float: left" src="/media_attachments_iframe/doesntmatter"></iframe>'
  end

  it "fixes the precise broken style caused by the old datafix in the various quiz data points" do
    quiz_description = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    question_text_1 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    question_text_2 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    question_text_3 = "<iframe style=\"width:px; height:px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    answer_text_1 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    answer_text_2 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    answer_text_3 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    answer_text_4 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    answer_text_5 = "<iframe style=\"width: px; height: px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
    answer_text_6 = "<iframe style=\"width:px; height:px;\" src=\"/media_attachments_iframe/whatever\"></iframe>"
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
    DataFixup::SetSizingForMediaAttachmentIframes.run
    q.reload
    expect(q.description).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_data[0]["question_text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_data[0]["answers"][0]["text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_data[0]["answers"][1]["text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_data[1]["question_text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_data[1]["answers"][0]["text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_data[1]["answers"][1]["text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_questions.first.question_data["question_text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_questions.first.question_data["answers"][0]["text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
    expect(q.quiz_questions.first.question_data["answers"][1]["text"]).to eq("<iframe style=\"width: 320px; height: 14.25rem;\" src=\"/media_attachments_iframe/whatever\"></iframe>")
  end
end
