#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "./messages_helper"

describe 'submission_comment_for_teacher' do
  before :once do
    submission_model
    @student.update!(name: "Stewie")
    @comment = @submission.add_comment(comment: "new comment")
  end

  let(:asset) { @comment }
  let(:notification_name) { "Submission Comment For Teacher" }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to match(/\/courses\/\d+\/assignments\/\d+\/submissions\/\d+/)
      expect(msg.body.include?("new comment on the submission")).to eq true
    end

    it "subject includes the comment author" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.subject).to include "Stewie"
    end

    it "body includes the comment author" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.body).to include "Stewie just made a new comment"
    end

    it "body includes the submission user" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.body).to include "on the submission for Stewie"
    end

    it "should render correct footer if replys are enabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body.include?("responding to this message")).to eq true
    end

    it "should render correct footer if replys are disabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = false
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body.include?("responding to this message")).to eq false
    end

    it "contains a 'from' name" do
      message = generate_message(notification_name, path_type, asset)
      message.infer_defaults
      expect(message.from_name).to eq "Stewie"
    end

    context "assignment is anonymous and muted" do
      before(:once) do
        @assignment.update!(anonymous_grading: true, muted: true)
        @comment.reload
      end

      it "subject includes an anonymized comment author" do
        msg = generate_message(notification_name, path_type, asset)
        expect(msg.subject).to include "Student (#{@submission.anonymous_id})"
      end

      it "body includes the comment author" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include "Student (#{@submission.anonymous_id}) just made a new comment"
      end

      it "body includes the submission user" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.body).to include "on the submission for Student (#{@submission.anonymous_id})"
      end

      it "anonymizes the 'from' name" do
        message = generate_message(notification_name, path_type, asset)
        message.infer_defaults
        expect(message.from_name).to eq "Anonymous User"
      end
    end
  end

  context ".email.html" do
    let(:path_type) { :email }

    it "renders" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.html_body).to include "new comment on the submission"
    end

    it "subject includes the comment author" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.subject).to include "Stewie"
    end

    it "body includes the comment author" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.html_body).to include "Stewie just made a new comment"
    end

    it "body includes the submission user" do
      message = generate_message(notification_name, path_type, asset)
      expect(message.html_body).to include "on the submission for Stewie"
    end

    it "renders correct footer if replys are enabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
      message = generate_message(notification_name, path_type, asset)
      html = Nokogiri::HTML(message.html_body)
      expect(html.at_css("a")["href"]).to include("mailto:")
    end

    it "contains a 'from' name" do
      message = generate_message(notification_name, path_type, asset)
      message.infer_defaults
      expect(message.from_name).to eq "Stewie"
    end

    context "assignment is anonymous and muted" do
      before(:once) do
        @assignment.update!(anonymous_grading: true, muted: true)
        @comment.reload
      end

      it "subject includes an anonymized comment author" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.subject).to include "Student (#{@submission.anonymous_id})"
      end

      it "body includes the comment author" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.html_body).to include "Student (#{@submission.anonymous_id}) just made a new comment"
      end

      it "body includes the submission user" do
        message = generate_message(notification_name, path_type, asset)
        expect(message.html_body).to include "on the submission for Student (#{@submission.anonymous_id})"
      end

      it "anonymizes the 'from' name" do
        message = generate_message(notification_name, path_type, asset)
        message.infer_defaults
        expect(message.from_name).to eq "Anonymous User"
      end
    end
  end
end
