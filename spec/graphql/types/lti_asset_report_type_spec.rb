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

describe Types::LtiAssetReportType do
  def make_reports(submission, ap1, ap2)
    rep1 = lti_asset_report_model(
      submission:,
      asset_processor: ap1,
      title: "abc",
      report_type: "t1",
      workflow_state: "deleted"
    )
    rep2 = lti_asset_report_model(
      asset_processor: ap1,
      title: "def",
      report_type: "t2",
      comment: nil,
      processing_progress: "Failed",
      error_code: "error_code2",
      priority: 1,
      indication_color: "#FF0000",
      indication_alt: "indication_alt1",
      result: "result2result2result2result2result2result2result2result2result2result2result2",
      asset: lti_asset_model(
        submission:,
        submission_attempt: 2
      )
    )
    rep3 = lti_asset_report_model(
      submission:,
      asset_processor: ap2,
      title: "ghi",
      report_type: "t3",
      comment: "comment3",
      processing_progress: "Processing",
      priority: 2,
      error_code: nil,
      indication_color: "#00FF00",
      indication_alt: "indication_alt2",
      result: "result3"
    )
    rep4 = lti_asset_report_model(
      submission:,
      asset_processor: ap2,
      title: "jkl",
      report_type: "t4",
      comment: "comment4",
      priority: 3,
      error_code: nil,
      indication_color: nil,
      indication_alt: nil,
      processing_progress: "UnrecognizedCountsAsNotReady",
      result: nil
    )
    [rep1, rep2, rep3, rep4]
  end

  before(:once) do
    @ap_student = student_in_course(course: @course, active_all: true).user
    @ap_teacher = teacher_in_course(course: @course, active_all: true).user
    @ap_assignment = @course.assignments.create!(name: "asdf", submission_types: "online_text_entry", points_possible: 10)
    @ap_submission = @ap_assignment.grade_student(@student, score: 8, grader: @teacher, student_entered_score: 13).first

    @ap1 = lti_asset_processor_model(assignment: @ap_submission.assignment)
    @ap2 = lti_asset_processor_model(assignment: @ap_submission.assignment)
    @rep1, @rep2, @rep3, @rep4 = make_reports(@ap_submission, @ap1, @ap2)
  end

  before do
    @submission_type = GraphQLTypeTester.new(
      @ap_submission,
      current_user: @ap_teacher,
      request: ActionDispatch::TestRequest.create
    )

    @submission_type_for_student = GraphQLTypeTester.new(@ap_submission, current_user: @ap_student, request: ActionDispatch::TestRequest.create)
  end

  def rep_query(node)
    query = "ltiAssetReportsConnection { nodes { #{node} } }"
    @submission_type.resolve(query)
  end

  it "is accessible through ltiAssetReportsConnection (active reports only)" do
    expect(rep_query("title")).to match_array(%w[def ghi jkl])
  end

  context "when the lti_asset_processor feature is disabled" do
    before { @ap_submission.root_account.disable_feature! :lti_asset_processor }
    after { @ap_submission.root_account.enable_feature! :lti_asset_processor }

    it { expect(rep_query("title")).to be_nil }
  end

  it "provides processorId" do
    expected_ap_ids = [@ap1, @ap2, @ap2].map { it.id.to_s }
    expect(rep_query("processorId")).to match_array(expected_ap_ids)
  end

  it "provides processorType" do
    expect(rep_query("reportType")).to match_array(%w[t2 t3 t4])
  end

  it "provides attachmendId through asset" do
    expected_att_ids = [@rep2, @rep3, @rep4].map { it.asset.attachment_id&.to_s }
    expect(rep_query("asset { attachmentId }")).to match_array(expected_att_ids)
  end

  it "provides submissionAttempt through asset" do
    expected_submission_attempts = [@rep2, @rep3, @rep4].map { it.asset.submission_attempt }
    expect(rep_query("asset { submissionAttempt }")).to match_array(expected_submission_attempts)
  end

  it "provides comment" do
    expect(rep_query("comment")).to match_array([nil, "comment3", "comment4"])
  end

  it "provides errorCode" do
    expect(rep_query("errorCode")).to match_array(["error_code2", nil, nil])
  end

  it "provides indicationAlt" do
    expect(rep_query("indicationAlt")).to match_array(["indication_alt1", "indication_alt2", nil])
  end

  it "provides indicationColor" do
    expect(rep_query("indicationColor")).to match_array(["#FF0000", "#00FF00", nil])
  end

  it "provides ltiLaunchUrlPath" do
    expect(rep_query("launchUrlPath")).to \
      match_array([@rep2, @rep3, @rep4].map(&:launch_url_path))
  end

  it "provides priority" do
    expect(rep_query("priority")).to match_array([1, 2, 3])
  end

  it "provides processingProgress" do
    expect(rep_query("processingProgress")).to match_array(%w[Failed Processing NotReady])
  end

  it "provides result" do
    expected = [
      "result2result2result2result2result2result2result2result2result2result2result2",
      "result3",
      nil,
    ]
    expect(rep_query("result")).to match_array(expected)
  end

  it "provides resultTruncated" do
    expect(rep_query("resultTruncated")).to match_array([@rep2, @rep3, @rep4].map(&:result_truncated))
  end
end
