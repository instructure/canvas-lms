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

require "spec_helper"
require_relative "../../app/services/auto_grade_orchestration_service"
require_relative "../../app/services/grade_service"
require_relative "../../app/services/comments_service"
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
    delayed_job_double = instance_double("Delayed::Job", attempts: 1)
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
        service = AutoGradeOrchestrationService.new(course:)
        grade_service = instance_double(GradeService)

        allow(GradeService).to receive(:new).and_return(grade_service)
        allow(grade_service).to receive(:call).and_return([
                                                            { "description" => "Grammar", "points" => 4, "comments" => "Good grammar" },
                                                            { "description" => "Organization", "points" => 3, "comments" => "Well organized" }
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
          root_account_uuid:
        )
        expect(grade_service).to have_received(:call)
      end

      it "raises error when GradeService doesn't return all missing criteria" do
        service = AutoGradeOrchestrationService.new(course:)
        grade_service = instance_double(GradeService)

        allow(GradeService).to receive(:new).and_return(grade_service)
        allow(grade_service).to receive(:call).and_return([
                                                            { "description" => "Grammar", "points" => 4, "comments" => "Some grammar issues" }
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
    end
  end

  describe "#generate_comments" do
    context "when generating comments for a submission" do
      before do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        submission.attempt = 1
        submission.save!
        rubric_association
      end

      it "generates comments for all criteria in the rubric" do
        service = AutoGradeOrchestrationService.new(course:)
        comment_service = instance_double(CommentsService)

        auto_grade_result = AutoGradeResult.create!(
          submission:,
          attempt: submission.attempt,
          grade_data: [
            { "description" => "Content", "points" => 8, "comments" => "Good content" },
            { "description" => "Grammar", "points" => 4 }, # Missing comments
            { "description" => "Organization", "points" => 3 } # Missing comments
          ],
          root_account_id: root_account.id,
          grading_attempts: 1
        )

        allow(CommentsService).to receive(:new).and_return(comment_service)
        allow(comment_service).to receive(:call).and_return(
          [
            { "description" => "Grammar", "points" => 4, "comments" => "Good grammar" },
            { "description" => "Organization", "points" => 3, "comments" => "Well organized" }
          ]
        )

        result = service.generate_comments(
          assignment_text:,
          root_account_uuid:,
          submission:,
          auto_grade_result:,
          progress:
        )

        missing_criteria_data = [
          { "description" => "Grammar", "points" => 4 },
          { "description" => "Organization", "points" => 3 }
        ]

        expect(CommentsService).to have_received(:new).with(
          assignment: assignment_text,
          grade_data: missing_criteria_data,
          root_account_uuid:
        )
        expect(comment_service).to have_received(:call)
        expect(result.grade_data.all? { |item| item["comments"].present? }).to be true
      end

      it "raises error when comments are missing for some criteria" do
        service = AutoGradeOrchestrationService.new(course:)
        comment_service = instance_double(CommentsService)

        auto_grade_result = AutoGradeResult.create!(
          submission:,
          attempt: submission.attempt,
          grade_data: [
            { "description" => "Content", "points" => 8, "comments" => "Good content" },
            { "description" => "Grammar", "points" => 4 }, # Missing comments
            { "description" => "Organization", "points" => 3 } # Missing comments
          ],
          root_account_id: root_account.id,
          grading_attempts: 1
        )

        allow(CommentsService).to receive(:new).and_return(comment_service)
        allow(comment_service).to receive(:call).and_return([
                                                              { "description" => "Grammar", "points" => 4, "comments" => "Good grammar" }
                                                            ])

        allow(service).to receive(:get_criteria_missing_comments)
          .with(any_args)
          .and_return(["Organization"])

        expect do
          service.generate_comments(
            assignment_text:,
            root_account_uuid:,
            submission:,
            auto_grade_result:,
            progress:
          )
        end.to raise_error(Delayed::RetriableError, /Number of comments.*is less than the number of rubric criteria/)
      end
    end
  end
end
