# frozen_string_literal: true

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

require_relative "messages_helper"

describe "submission_graded" do
  before :once do
    submission_model
  end

  let(:asset) { @submission }
  let(:notification_name) { :submission_graded }

  include_examples "a message"

  it "includes the submission's submitter name if receiver is not the submitter and has the setting turned on" do
    observer = user_model
    message = generate_message(:submission_graded, :summary, asset, user: observer)
    expect(message.body).not_to match("For #{@submission.user.name}")

    observer.preferences[:send_observed_names_in_notifications] = true
    observer.save!
    message = generate_message(:submission_graded, :summary, asset, user: observer)
    expect(message.body).to match("For #{@submission.user.name}")
  end

  it "does not fail for twitter message" do
    observer = user_model
    observer.preferences[:send_observed_names_in_notifications] = true
    message = generate_message(:submission_graded, :twitter, asset, user: observer)
    expect(message.body).to match(@submission.user.name)
  end

  context "with a graded submission and sending scores in emails is allowed" do
    before do
      @assignment.points_possible = 100
      @assignment.save!
      @submission.score = 99
      @submission.workflow_state = "graded"
      @submission.save!
      @student.preferences[:send_scores_in_emails] = true
      @student.save!
    end

    it "shows score" do
      summary = generate_message(:submission_graded, :summary, asset, user: @student)
      expect(summary.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      email = generate_message(:submission_graded, :email, asset, user: @student)
      expect(email.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      expect(email.html_body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      twitter = generate_message(:submission_graded, :twitter, asset, user: @student)
      expect(twitter.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
      sms = generate_message(:submission_graded, :sms, asset, user: @student)
      expect(sms.body).to include("score: #{@submission.score} out of #{@assignment.points_possible}")
    end

    it "shows grade instead when user is quantitative data restricted" do
      course_root_account = @assignment.course.root_account
      # truthy feature flag
      course_root_account.enable_feature! :restrict_quantitative_data

      # truthy setting
      course_root_account.settings[:restrict_quantitative_data] = { value: true, locked: true }
      course_root_account.save!
      @assignment.course.restrict_quantitative_data = true
      @assignment.course.save!

      summary = generate_message(:submission_graded, :summary, asset, user: @student)
      expect(summary.body).to include("grade: A")
      email = generate_message(:submission_graded, :email, asset, user: @student)
      expect(email.body).to include("grade: A")
      expect(email.html_body).to include("grade: A")
      twitter = generate_message(:submission_graded, :twitter, asset, user: @student)
      expect(twitter.body).to include("grade: A")
      sms = generate_message(:submission_graded, :sms, asset, user: @student)
      expect(sms.body).to include("grade: A")
    end
  end
end
