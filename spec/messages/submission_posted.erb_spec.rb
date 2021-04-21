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
  let_once(:assignment) { course.assignments.create!(title: "assignment 1") }
  let_once(:course) { Course.create!(name: "course 1") }
  let_once(:notification_name) { :submission_posted }
  let_once(:student) { course.enroll_student(User.create!, enrollment_state: :active).user }
  let_once(:submission) { assignment.submissions.find_by!(user: student) }
  let_once(:submission_url) { "/courses/#{course.id}/assignments/#{assignment.id}/submissions/#{student.id}" }

  context "email" do
    let_once(:path_type) { :email }

    it "includes a message subject" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.subject).to eql "Submission Posted: assignment 1, course 1"
    end

    it "includes a message body" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.body).to include "Your instructor has released grade changes and new comments"
    end

    it "includes a link to the submission" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.body).to include submission_url
    end

    it "html includes a message body" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.html_body).to include "Your instructor has released grade changes and new comments"
    end

    it "html includes a link to the submission" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.html_body).to include submission_url
    end
  end

  context "sms" do
    let_once(:path_type) { :sms }

    it "includes a message subject" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.subject).to eql "Canvas Alert"
    end

    it "includes a message body" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.body).to include "Your instructor has released grade changes and new comments"
    end

    it "includes a link to the submission" do
      message = generate_message(notification_name, path_type, asset, {})
      expect(message.body).to include submission_url
    end
  end

  context "summary" do
    let_once(:path_type) { :summary }

    it "includes a message subject" do
      message = generate_message(notification_name, path_type, asset, {})
      expected_subject = "Grade changes and new comments released for: #{assignment.title}, #{course.name}"
      expect(message.subject).to eql expected_subject
    end
  end
end
