# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateSubmissionsReadState do
  def mutation_str(
    ids: [],
    read: true
  )
    <<~GQL
      mutation {
        updateSubmissionsReadState(input: {submissionIds: #{ids}, read: #{read}}) {
          submissions {
            _id
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  before(:once) do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment = @course.assignments.create!(title: "Example Assignment")
    @submission = @assignment.submit_homework(
      @student,
      submission_type: "online_text_entry",
      body: "body"
    )
    @student_comment = @submission.submission_comments.create!(author: @student, comment: "whats up")
    @teacher_comment = @submission.submission_comments.create!(author: @teacher, comment: "teachers whats up")
  end

  it "marks submission as unread" do
    @submission.change_read_state("read", @teacher)
    result = run_mutation({ ids: [@submission.id], read: false })
    expect(result.dig("data", "updateSubmissionsReadState", "errors")).to be_nil
    expect(result.dig("data", "updateSubmissionsReadState", "submissions")).to include({ _id: @submission.id.to_s })
    expect(@submission.read_state(@teacher)).to eq "unread"
  end

  it "marks submission as read" do
    @submission.change_read_state("unread", @teacher)
    result = run_mutation({ ids: [@submission.id], read: true })

    expect(result.dig("data", "updateSubmissionsReadState", "errors")).to be_nil
    expect(result.dig("data", "updateSubmissionsReadState", "submissions")).to include({ _id: @submission.id.to_s })
    expect(@submission.read_state(@teacher)).to eq "read"
  end

  describe "error handling" do
    it "returns a list of submissions not found" do
      @submission.change_read_state("unread", @teacher)
      submission_id_that_does_not_exist = "4"
      result = run_mutation({ ids: [submission_id_that_does_not_exist, @submission.id], read: true })

      expect(result.dig("data", "updateSubmissionsReadState", "errors")).not_to be_nil
      expect(result.dig("data", "updateSubmissionsReadState", "submissions")).to include({ _id: @submission.id.to_s })
      expect(result.dig("data", "updateSubmissionsReadState", "errors")).to include({ attribute: submission_id_that_does_not_exist, message: "Unable to find Submission" })
      expect(@submission.read_state(@teacher)).to eq "read"
    end

    it "returns an array of submissions that the user is unauthorized to read" do
      @submission.change_read_state("unread", @teacher)
      result = run_mutation({ ids: [@submission.id], read: true }, user_model)

      expect(result.dig("data", "updateSubmissionsReadState", "errors")).not_to be_nil
      expect(result.dig("data", "updateSubmissionsReadState", "submissions")).to be_nil
      expect(result.dig("data", "updateSubmissionsReadState", "errors")).to include({ attribute: @submission.id.to_s, message: "Not authorized to read Submission" })
      expect(@submission.read_state(@teacher)).to eq "unread"
    end
  end
end
