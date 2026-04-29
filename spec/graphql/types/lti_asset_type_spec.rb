# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Types::LtiAssetType do
  before(:once) do
    @ap_student = student_in_course(course: @course, active_all: true).user
    @ap_teacher = teacher_in_course(course: @course, active_all: true).user
    @ap_assignment = @course.assignments.create!(name: "asdf", submission_types: "online_upload", points_possible: 10)
    @ap_submission = @ap_assignment.grade_student(@student, score: 8, grader: @ap_teacher, student_entered_score: 13).first
    @attachment = attachment_with_context @ap_student, { display_name: "a1.txt", uploaded_data: StringIO.new("hello") }
    @ap1 = lti_asset_processor_model(assignment: @ap_submission.assignment)

    @report = lti_asset_report_model(
      asset_processor: @ap1,
      attachment: @attachment,
      comment: "comment4",
      processing_progress: "NotReady",
      report_type: "t4",
      submission: @ap_submission,
      title: "jkl"
    )
  end

  before do
    @submission_type = GraphQLTypeTester.new(
      @ap_submission,
      current_user: @ap_teacher,
      request: ActionDispatch::TestRequest.create
    )

    @submission_type_for_student = GraphQLTypeTester.new(@ap_submission, current_user: @ap_student, request: ActionDispatch::TestRequest.create)
  end

  def rep_query
    query = <<~TEXT
      query MyQuery {
        submission (id: #{@ap_submission.id}) {
          _id
          ltiAssetReportsConnection {
            nodes {
              asset {
                _id
                attachmentId
                attachmentName
                submissionAttempt
                submissionId
              }
            }
          }
        }
      }
    TEXT
    CanvasSchema.execute(query, context: { current_user: @ap_teacher })
  end

  it "is accessible through ltiAssetReportsConnection" do
    result = rep_query.to_h["data"]
    asset = @ap_submission.lti_assets.take

    expected_data = {
      "submission" => {
        "_id" => @ap_submission.id.to_s,
        "ltiAssetReportsConnection" => {
          "nodes" => [
            {
              "asset" => {
                "_id" => asset.id.to_s,
                "attachmentId" => asset.attachment_id.to_s,
                "attachmentName" => "a1.txt",
                "submissionAttempt" => nil,
                "submissionId" => @ap_submission.id.to_s
              }
            }
          ]
        }
      }
    }

    expect(result).to match(expected_data)
  end
end
