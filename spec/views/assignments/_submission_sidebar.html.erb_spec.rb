# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../views_helper"

describe "assignments/_submission_sidebar" do
  let(:course) { Course.create! }
  let(:student) { User.create! }
  let(:teacher) { User.create! }
  let(:assignment) { course.assignments.create! }
  let(:submission) { assignment.submissions.find_by(user: student) }

  before do
    course.enroll_student(student)
    course.enroll_teacher(teacher)
    view_context(course, student)
    assign(:assigned_assessments, [])
    assign(:assignment, assignment)
  end

  context "when submission was proxy" do
    it "renders the proxy submitter's name" do
      submission.update!(proxy_submitter: teacher)
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div.content").text).to include teacher.short_name
    end
  end

  context "when assignment posts manually" do
    before { assignment.ensure_post_policy(post_manually: true) }

    it "renders a grade when a grade exists and the submission is posted" do
      assignment.grade_student(student, grader: teacher, score: 23)
      submission.update!(posted_at: Time.zone.now)
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div.module div").text).to include "Grade: 23"
    end

    it "does not render a grade when a grade exists and the submission is not posted" do
      assignment.grade_student(student, grader: teacher, score: 23)
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div.module div").text).not_to include "Grade: 23"
    end

    it "renders submission comments when the submission is posted" do
      comment = submission.add_comment(author: teacher, comment: "a comment!")
      submission.update!(posted_at: Time.zone.now)
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div#comment-#{comment.id}").text).to include "a comment!"
    end

    it "does not render submission comments when the submission is not posted" do
      comment = submission.add_comment(author: teacher, comment: "a comment!")
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div#comment-#{comment.id}").text).not_to include "a comment!"
    end

    it "must render when the submission type is online_quiz but assignment lacks of quiz.id" do
      submission[:submission_type] = "online_quiz"
      assign(:current_user_submission, submission)
      render
      expect(response).not_to be_nil
    end
  end

  context "when assignment posts automatically" do
    before { assignment.ensure_post_policy(post_manually: false) }

    it "renders a grade" do
      assignment.grade_student(student, grader: teacher, score: 23)
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div.module div").text).to include "Grade: 23"
    end

    it "renders a letter grade with trailing en-dash replaced with minus" do
      en_dash = "-"
      minus = "−"
      assignment.update!(grading_type: "letter_grade", points_possible: 10)
      assignment.grade_student(student, grader: teacher, grade: "B#{en_dash}")
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div.module div").text).to include "Grade: B#{minus}"
    end

    it "renders submission comments" do
      comment = submission.add_comment(author: teacher, comment: "a comment!")
      assign(:current_user_submission, submission)
      render
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("div#comment-#{comment.id}").text).to include "a comment!"
    end
  end
end
