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

describe "submissions_posted" do
  let_once(:asset) { assignment }
  let_once(:assignment) { course.assignments.create!(title: "assignment 1") }
  let_once(:assignment_url) { "/courses/#{course.id}/assignments/#{assignment.id}" }
  let_once(:course) { Course.create!(name: "course 1") }
  let_once(:notification_name) { :submissions_posted }

  context "email" do
    let_once(:message_options) { { data: { graded_only: false } } }
    let_once(:path_type) { :email }

    it "includes a message subject" do
      message = generate_message(notification_name, path_type, asset, message_options)
      expect(message.subject).to eql "Submissions Posted: assignment 1, course 1"
    end

    it "includes a link to the assignment" do
      message = generate_message(notification_name, path_type, asset, message_options)
      expect(message.body).to include assignment_url
    end

    it "html includes a link to the submission" do
      message = generate_message(notification_name, path_type, asset, message_options)
      expect(message.html_body).to include assignment_url
    end

    context "when posted for everyone" do
      let_once(:message_options) { { data: { graded_only: false } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.body).to include "Grade changes and comments have been released for everyone."
      end

      it "html includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.html_body).to include "Grade changes and comments have been released for everyone."
      end
    end

    context "when posted for everyone in sections" do
      let_once(:message_options) { { data: { graded_only: false, section_names: ["sec1", "sec2", "sec3"] } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone in sections: sec1, sec2, and sec3."
        expect(message.body).to include body_text
      end

      it "html includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone in sections: sec1, sec2, and sec3."
        expect(message.html_body).to include body_text
      end
    end

    context "when posted for graded only" do
      let_once(:message_options) { { data: { graded_only: true } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.body).to include "Grade changes and comments have been released for everyone graded."
      end

      it "html includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.html_body).to include "Grade changes and comments have been released for everyone graded."
      end
    end

    context "when posted for graded only in sections" do
      let_once(:message_options) { { data: { graded_only: true, section_names: ["sec1", "sec2", "sec3"] } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone graded in sections: sec1, sec2, and sec3."
        expect(message.body).to include body_text
      end

      it "html includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone graded in sections: sec1, sec2, and sec3."
        expect(message.html_body).to include body_text
      end
    end
  end

  context "sms" do
    let_once(:message_options) { { data: { graded_only: false } } }
    let_once(:path_type) { :sms }

    it "includes a message subject" do
      message = generate_message(notification_name, path_type, asset, message_options)
      expect(message.subject).to eql "Canvas Alert"
    end

    it "includes a link to the assignment" do
      message = generate_message(notification_name, path_type, asset, message_options)
      expect(message.body).to include assignment_url
    end

    context "when posted for everyone" do
      let_once(:message_options) { { data: { graded_only: false } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.body).to include "Grade changes and comments have been released for everyone."
      end
    end

    context "when posted for everyone in sections" do
      let_once(:message_options) { { data: { graded_only: false, section_names: ["sec1", "sec2", "sec3"] } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone in sections: sec1, sec2, and sec3."
        expect(message.body).to include body_text
      end
    end

    context "when posted for graded only" do
      let_once(:message_options) { { data: { graded_only: true } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.body).to include "Grade changes and comments have been released for everyone graded."
      end
    end

    context "when posted for graded only in sections" do
      let_once(:message_options) { { data: { graded_only: true, section_names: ["sec1", "sec2", "sec3"] } } }

      it "includes a message body" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone graded in sections: sec1, sec2, and sec3."
        expect(message.body).to include body_text
      end
    end
  end

  context "summary" do
    let_once(:path_type) { :summary }

    context "when posted for everyone" do
      let_once(:message_options) { { data: { graded_only: false } } }

      it "includes a message subject" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.subject).to include "Grade changes and comments have been released for everyone."
      end
    end

    context "when posted for everyone in sections" do
      let_once(:message_options) { { data: { graded_only: false, section_names: ["sec1", "sec2", "sec3"] } } }

      it "includes a message subject" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone in sections: sec1, sec2, and sec3."
        expect(message.subject).to include body_text
      end
    end

    context "when posted for graded only" do
      let_once(:message_options) { { data: { graded_only: true } } }

      it "includes a message subject" do
        message = generate_message(notification_name, path_type, asset, message_options)
        expect(message.subject).to include "Grade changes and comments have been released for everyone graded."
      end
    end

    context "when posted for graded only in sections" do
      let_once(:message_options) { { data: { graded_only: true, section_names: ["sec1", "sec2", "sec3"] } } }

      it "includes a message subject" do
        message = generate_message(notification_name, path_type, asset, message_options)
        body_text = "Grade changes and comments have been released for everyone graded in sections: sec1, sec2, and sec3."
        expect(message.subject).to include body_text
      end
    end
  end
end
