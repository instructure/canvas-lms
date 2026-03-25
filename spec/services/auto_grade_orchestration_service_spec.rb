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

require_relative "../factory_bot_spec_helper"

RSpec.describe AutoGradeOrchestrationService do
  # Test data setup
  let(:assignment_text) { "Write an essay about your summer vacation" }
  let(:essay) { "I went to the beach and had a great time..." }
  let(:root_account_uuid) { "mock-root-uuid" }

  # Create a root account with UUID
  let(:root_account) { Account.create!(uuid: root_account_uuid, root_account: nil) }

  # Use FactoryBot for course and assignment
  let(:course) { create(:course, account: root_account, name: "Summer Vacation Course") }
  let(:user) { User.create!(name: "John Doe") }
  let(:assignment) do
    create(:assignment,
           course:,
           title: "Summer Vacation Essay",
           description: assignment_text)
  end

  # Simplified rubric data
  let(:rubric_data) do
    [
      { id: "criteria_1",
        description: "Content",
        points: 4,
        ratings: [{ id: "rating_1", long_description: "Meets requirements", points: 3 }] },
      { id: "criteria_2",
        description: "Grammar",
        points: 4,
        ratings: [{ id: "rating_2", long_description: "Excellent grammar", points: 4 }] },
      { id: "criteria_3",
        description: "Organization",
        points: 3,
        ratings: [{ id: "rating_3", long_description: "Clear structure and flow", points: 3 }] }
    ]
  end

  # Create the rubric and association
  let(:rubric) do
    Rubric.create!(
      title: "Essay Rubric",
      context: course,
      data: rubric_data,
      points_possible: 8
    )
  end

  let(:rubric_association) do
    RubricAssociation.create!(
      rubric:,
      association_object: assignment,
      context: course,
      purpose: "grading"
    )
  end

  let(:submission) do
    Submission.create!(
      user:,
      assignment:,
      body: essay,
      attempt: 1
    )
  end

  let(:progress) do
    progress = Progress.create!(
      context: course,
      tag: "auto_grade_submission",
      workflow_state: "running"
    )
    delayed_job_double = instance_double(Delayed::Job, attempts: 1)
    allow(progress).to receive(:delayed_job).and_return(delayed_job_double)
    progress
  end

  describe "#get_grade_data" do
    context "when there are existing grades and missing criteria" do
      before do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        submission.attempt = 1
        submission.save!
        rubric_association

        AutoGradeResult.create!(
          submission:,
          attempt: submission.attempt,
          grade_data: [{ description: "Content", points: 8, comments: "Good content" }],
          root_account_id: root_account.id,
          grading_attempts: 1
        )
      end

      it "calls GradeService with only missing criteria and merges results" do
        service = AutoGradeOrchestrationService.new(course:, current_user: user)
        grade_service = instance_double(GradeService)

        allow(GradeService).to receive(:new).and_return(grade_service)
        allow(grade_service).to receive(:call).and_return([
                                                            { "description" => "Grammar", "rating" => 4, "comments" => "Good grammar" },
                                                            { "description" => "Organization", "rating" => 3, "comments" => "Well organized" }
                                                          ])

        service.get_grade_data(
          assignment_text:,
          root_account_uuid:,
          submission:,
          progress:
        )

        expect(GradeService).to have_received(:new).with(
          assignment: assignment_text,
          essay:,
          rubric: rubric_data[1..],
          root_account_uuid:,
          current_user: user
        )
        expect(grade_service).to have_received(:call)
      end

      it "raises error when GradeService doesn't return all missing criteria" do
        service = AutoGradeOrchestrationService.new(course:, current_user: user)
        grade_service = instance_double(GradeService)

        allow(GradeService).to receive(:new).and_return(grade_service)
        allow(grade_service).to receive(:call).and_return([
                                                            {
                                                              "id" => "grammar_criterion_id",
                                                              "description" => "Grammar",
                                                              "rating" => {
                                                                "id" => "grammar_rating_id",
                                                                "description" => "Some grammar issues",
                                                                "rating" => 4.0,
                                                                "reasoning" => "Some grammar issues"
                                                              }
                                                            }
                                                          ])

        expect do
          service.get_grade_data(
            assignment_text:,
            root_account_uuid:,
            submission:,
            progress:
          )
        end.to raise_error(Delayed::RetriableError, /Number of graded criteria.*is less than the number of rubric criteria/)
      end

      it "deduplicates duplicate items from GradeService by description" do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        submission.update!(attempt: 1)
        rubric_association

        agr = AutoGradeResult.find_by!(submission:, attempt: submission.attempt)
        agr.update!(
          grade_data: [
            {
              "id" => "content_criterion_id",
              "description" => "Content",
              "rating" => {
                "id" => "content_rating_id",
                "description" => "Good content",
                "rating" => 8.0,
                "reasoning" => "Good content"
              }
            }
          ]
        )

        service = AutoGradeOrchestrationService.new(course:, current_user: user)
        grade_service = instance_double(GradeService)

        allow(GradeService).to receive(:new).and_return(grade_service)
        allow(grade_service).to receive(:call).and_return([
                                                            {
                                                              "id" => "grammar_criterion_id",
                                                              "description" => "Grammar",
                                                              "rating" => {
                                                                "id" => "grammar_rating_high",
                                                                "description" => "Good grammar (a)",
                                                                "rating" => 4.0,
                                                                "reasoning" => "Good grammar (a)."
                                                              }
                                                            },
                                                            {
                                                              "id" => "grammar_criterion_id",
                                                              "description" => "Grammar",
                                                              "rating" => {
                                                                "id" => "grammar_rating_low",
                                                                "description" => "Good grammar (b)",
                                                                "rating" => 3.0,
                                                                "reasoning" => "Good grammar (b)."
                                                              }
                                                            },
                                                            {
                                                              "id" => "organization_criterion_id",
                                                              "description" => "Organization",
                                                              "rating" => {
                                                                "id" => "organization_rating_id",
                                                                "description" => "Well organized",
                                                                "rating" => 3.0,
                                                                "reasoning" => "Well organized."
                                                              }
                                                            }
                                                          ])

        result = service.get_grade_data(
          assignment_text:,
          root_account_uuid:,
          submission:,
          progress:
        )

        grammar_records = result.grade_data.select { |item| item["description"] == "Grammar" }
        expect(grammar_records.length).to eq(1)
        grammar_record = grammar_records.first

        expect(grammar_record).not_to be_nil
        expect(grammar_record["rating"]["rating"]).to eq(3)
        expect(grammar_record["rating"]["description"]).to eq("Good grammar (b)")
        expect(grammar_record["rating"]["reasoning"]).to eq("Good grammar (b). This work sits between two ratings for this criterion. The lower rating was applied for consistency.")
      end
    end

    context "when there are no missing criteria" do
      it "does not call GradeService and leaves grade_data unchanged" do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        submission.update!(attempt: 1)
        rubric_association

        initial_data = [
          { "description" => "Content", "rating" => 8, "comments" => "Good content" },
          { "description" => "Grammar", "rating" => 4, "comments" => "Good grammar" },
          { "description" => "Organization", "rating" => 3, "comments" => "Well organized" }
        ]
        agr = AutoGradeResult.create!(
          submission:,
          attempt: submission.attempt,
          grade_data: initial_data,
          root_account_id: root_account.id,
          grading_attempts: 1
        )

        service = AutoGradeOrchestrationService.new(course:, current_user: user)

        expect(GradeService).not_to receive(:new)

        result = service.get_grade_data(
          assignment_text:,
          root_account_uuid:,
          submission:,
          progress:
        )

        expect(result.grade_data).to eq(initial_data)
        expect(agr.reload.grading_attempts).to eq(1)
      end
    end
  end

  describe "#handle_grading_failure" do
    let(:service) { AutoGradeOrchestrationService.new(course:, current_user: user) }
    let(:error_message) { "Grading failed: something went wrong" }

    context "on terminal failure" do
      let(:progress) do
        p = Progress.create!(context: course, tag: "auto_grade_submission", workflow_state: "running")
        delayed_job_double = instance_double(Delayed::Job, attempts: AutoGradeOrchestrationService::MAX_ATTEMPTS - 1)
        allow(p).to receive(:delayed_job).and_return(delayed_job_double)
        p
      end

      it "sets progress.message to a generic message for non-GraderErrors (retryable: false)" do
        service.handle_grading_failure(error_message:, submission:, auto_grade_result: nil, progress:, retryable: false)
        expect(progress.message).to eq("An error occurred while grading. Please try again later.")
      end

      it "sets progress.message to the specific error message for GraderErrors (retryable: true)" do
        service.handle_grading_failure(error_message:, submission:, auto_grade_result: nil, progress:, retryable: true)
        expect(progress.message).to eq(error_message)
      end

      it "calls progress.fail!" do
        expect(progress).to receive(:fail!)
        service.handle_grading_failure(error_message:, submission:, auto_grade_result: nil, progress:, retryable: false)
      end

      it "does not create an AutoGradeResult if one is not persisted" do
        expect do
          service.handle_grading_failure(error_message:, submission:, auto_grade_result: nil, progress:, retryable: false)
        end.not_to change(AutoGradeResult, :count)
      end

      it "updates error_message and increments grading_attempts on an existing AutoGradeResult" do
        rubric_association
        auto_grade_result = AutoGradeResult.create!(
          submission:,
          attempt: submission.attempt,
          grade_data: [{ "description" => "Content", "rating" => { "rating" => 3 } }],
          root_account_id: root_account.id,
          grading_attempts: 1
        )

        service.handle_grading_failure(error_message:, submission:, auto_grade_result:, progress:, retryable: false)

        auto_grade_result.reload
        expect(auto_grade_result.error_message).to eq(error_message)
        expect(auto_grade_result.grading_attempts).to eq(2)
      end
    end

    context "on retryable failure under AutoGradeOrchestrationService::MAX_ATTEMPTS" do
      it "raises Delayed::RetriableError" do
        expect do
          service.handle_grading_failure(error_message:, submission:, auto_grade_result: nil, progress:, retryable: true)
        end.to raise_error(Delayed::RetriableError, error_message)
      end

      it "does not call progress.fail!" do
        expect(progress).not_to receive(:fail!)
        begin
          service.handle_grading_failure(error_message:, submission:, auto_grade_result: nil, progress:, retryable: true)
        rescue Delayed::RetriableError
          nil
        end
      end
    end
  end

  describe "#run_auto_grader" do
    let(:service) { AutoGradeOrchestrationService.new(course:, current_user: user) }

    it "does not complete progress when get_grade_data returns nil" do
      allow(service).to receive(:get_grade_data).and_return(nil)
      expect(progress).not_to receive(:complete!)
      service.run_auto_grader(progress, submission)
    end

    it "completes progress with grade_data when get_grade_data returns a result" do
      rubric_association
      auto_grade_result = AutoGradeResult.create!(
        submission:,
        attempt: submission.attempt,
        grade_data: [{ "description" => "Content", "rating" => { "rating" => 3 } }],
        root_account_id: root_account.id,
        grading_attempts: 1
      )
      allow(service).to receive(:get_grade_data).and_return(auto_grade_result)

      expect(progress).to receive(:complete!)
      service.run_auto_grader(progress, submission)
      expect(progress.results).to eq(auto_grade_result.grade_data)
    end
  end
end
