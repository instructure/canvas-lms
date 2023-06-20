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
require_relative "messages_helper"

describe "submission_posted" do
  let_once(:asset) { submission }
  let_once(:assignment) do
    course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry", points_possible: 10)
  end
  let_once(:course) { Course.create!(name: "course 1") }
  let_once(:teacher) { course.enroll_teacher(User.create!, enrollment_state: :active).user }
  let_once(:notification_name) { :submission_posted }
  let_once(:student) { course.enroll_student(User.create!, enrollment_state: :active).user }
  let_once(:submission) { assignment.submissions.find_by!(user: student) }
  let_once(:submission_url) { "/courses/#{course.id}/assignments/#{assignment.id}/submissions/#{student.id}" }
  let(:root_account) { course.root_account }
  let(:message) { generate_message(notification_name, path_type, asset, { user: student }) }

  shared_examples "a view with graded info" do
    it "does not include 'graded' information if the submission has not been graded" do
      expect(message.body).not_to include "graded:"
    end

    it "includes 'graded' information if the submission has been graded" do
      Timecop.freeze(Time.zone.local(Time.now.year - 1, 12, 14, 13, 32, 8)) do
        assignment.grade_student(student, score: 8, grader: teacher)
        asset.reload
        expect(message.body).to include "graded: Dec 14 at 1:32pm"
      end
    end
  end

  shared_examples "a view with scores" do
    context "sending scores in emails disabled by root account" do
      before do
        root_account.settings[:allow_sending_scores_in_emails] = false
        root_account.save!
      end

      it "does not include scores in emails" do
        student.preferences[:send_scores_in_emails] = true
        student.save!
        assignment.grade_student(student, score: 8, grader: teacher)
        asset.reload
        expect(message.body).not_to include "score: 8.0 out of 10.0"
      end
    end

    context "sending scores in emails enabled by root account" do
      before do
        root_account.settings[:allow_sending_scores_in_emails] = true
        root_account.save!
      end

      it "includes scores in emails when the student prefers scores in emails and the submission has a score" do
        student.preferences[:send_scores_in_emails] = true
        student.save!
        assignment.grade_student(student, score: 8, grader: teacher)
        asset.reload
        expect(message.body).to include "score: 8.0 out of 10.0"
      end

      it "does not include submission scores when the student does not prefer scores in emails" do
        assignment.grade_student(student, score: 8, grader: teacher)
        asset.reload
        expect(message.body).not_to include "score: 8.0 out of 10.0"
      end

      it "shows grade instead when user is quantitative data restricted" do
        student.preferences[:send_scores_in_emails] = true
        student.save!

        course_root_account = assignment.course.root_account
        # truthy feature flag
        course_root_account.enable_feature! :restrict_quantitative_data

        # truthy setting
        course_root_account.settings[:restrict_quantitative_data] = { value: true, locked: true }
        course_root_account.save!
        assignment.course.restrict_quantitative_data = true
        assignment.course.save!

        assignment.grade_student(student, score: 10, grader: teacher)
        asset.reload
        expect(message.body).to include "grade: A"
      end
    end
  end

  context "email" do
    let_once(:path_type) { :email }

    it_behaves_like "a view with graded info"
    it_behaves_like "a view with scores"

    it "includes a message subject" do
      expect(message.subject).to eql "Submission Posted: assignment 1, course 1"
    end

    it "includes a message body" do
      expect(message.body).to include "Your instructor has released grade changes and new comments"
    end

    it "includes a link to the submission" do
      expect(message.body).to include submission_url
    end

    it "html includes a message body" do
      expect(message.html_body).to include "Your instructor has released grade changes and new comments"
    end

    it "html includes a link to the submission" do
      expect(message.html_body).to include submission_url
    end
  end

  context "sms" do
    let_once(:path_type) { :sms }

    it_behaves_like "a view with graded info"
    it_behaves_like "a view with scores"

    it "includes a message subject" do
      expect(message.subject).to eql "Canvas Alert"
    end

    it "includes a message body" do
      expect(message.body).to include "Your instructor has released grade changes and new comments"
    end

    it "includes a link to the submission" do
      expect(message.body).to include submission_url
    end
  end

  context "summary" do
    let_once(:path_type) { :summary }

    it_behaves_like "a view with graded info"
    it_behaves_like "a view with scores"

    it "includes a message subject" do
      expected_subject = "Grade changes and new comments released for: #{assignment.title}, #{course.name}"
      expect(message.subject).to eql expected_subject
    end
  end
end
