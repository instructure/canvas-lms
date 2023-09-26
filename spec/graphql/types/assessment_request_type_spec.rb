# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative "../graphql_spec_helper"

describe Types::AssessmentRequestType do
  before(:once) do
    student_in_course(active_all: true)
    @assignment = @course.assignments.create! name: "asdf", points_possible: 10, peer_reviews: true
    @submission = @assignment.grade_student(@student, score: 8, grader: @teacher).first
    reviewee = User.create!
    @course.enroll_user(reviewee, "StudentEnrollment", enrollment_state: "active")
    @assessment_request = @assignment.assign_peer_review(@student, reviewee)
  end

  let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @student) }

  it "works" do
    expect(submission_type.resolve("assignedAssessments { _id }").first).to eq @assessment_request.id.to_s
  end

  it "requires permission" do
    user2 = User.create!
    expect(submission_type.resolve("assignedAssessments { _id }", current_user: user2)).to be_nil
  end

  it "works for workflowState" do
    expect(submission_type.resolve("assignedAssessments { workflowState }").first).to eq @assessment_request.workflow_state
  end

  it "works for available?" do
    expect(submission_type.resolve("assignedAssessments { available }").first).to eq @assessment_request.available?
  end

  it "works for user" do
    expect(submission_type.resolve("assignedAssessments { user { _id } }").first).to eq @assessment_request.user.id.to_s
  end

  it "works for assetSubmissionType" do
    expect(submission_type.resolve("assignedAssessments { assetSubmissionType }").first).to eq @submission.submission_type
  end

  it "works for asset_id" do
    expect(submission_type.resolve("assignedAssessments { assetId }").first).to eq @assessment_request.asset_id.to_s
  end

  describe "with anonymous peer review disabled" do
    it "works for user" do
      expect(submission_type.resolve("assignedAssessments { user { _id } }").first).to eq @assessment_request.user.id.to_s
    end

    it "anonymizedUser should match the assessment request user" do
      expect(submission_type.resolve("assignedAssessments { anonymizedUser { _id } }").first).to eq @assessment_request.user.id.to_s
    end

    it "anonymousId should be null" do
      expect(submission_type.resolve("assignedAssessments { anonymousId }").first).to be_nil
    end
  end

  describe "with anonymous peer review enabled" do
    before(:once) { @assignment.update_attribute(:anonymous_peer_reviews, true) }

    it "works for user" do
      expect(submission_type.resolve("assignedAssessments { user { _id } }").first).to eq @assessment_request.user.id.to_s
    end

    it "anonymizedUser should be null" do
      expect(submission_type.resolve("assignedAssessments { anonymizedUser { _id } }").first).to be_nil
    end

    it "anonymousId should match the anonymous id of the asset" do
      expect(submission_type.resolve("assignedAssessments { anonymousId }").first).to eq @assessment_request.asset.anonymous_id.to_s
    end
  end
end
