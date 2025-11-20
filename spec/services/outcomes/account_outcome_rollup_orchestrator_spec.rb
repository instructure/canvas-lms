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

describe Outcomes::AccountOutcomeRollupOrchestrator do
  subject { described_class.new(account_id: account.id, outcome_id: outcome.id) }

  let(:account) { account_model }
  let(:sub_account) { account_model(parent_account: account) }
  let(:outcome) { outcome_model(context: account) }
  let(:course1) { course_model(account:) }
  let(:course2) { course_model(account: sub_account) }
  let(:course3) { course_model(account:) }

  before do
    course1.root_outcome_group.add_outcome(outcome)
    course2.root_outcome_group.add_outcome(outcome)
  end

  describe ".process_account_outcome_change" do
    it "creates a progress object and enqueues the job" do
      expect(Progress).to receive(:create!).with(
        context: account,
        tag: "account_outcome_rollup_orchestrator",
        message: "Processing outcome rollup calculations"
      ).and_return(double("progress", process_job: nil))

      progress = described_class.process_account_outcome_change(
        account_id: account.id,
        outcome_id: outcome.id
      )

      expect(progress).not_to be_nil
    end

    it "passes correct parameters to process_job" do
      progress = double("progress")
      allow(Progress).to receive(:create!).and_return(progress)

      expect(progress).to receive(:process_job).with(
        described_class,
        :perform_rollup_calculation,
        {
          priority: Delayed::LOW_PRIORITY,
          singleton: "AccountOutcomeRollupOrchestrator:#{account.id}:#{outcome.id}",
          on_conflict: :use_earliest,
          max_attempts: 3
        },
        account_id: account.id,
        outcome_id: outcome.id
      )

      described_class.process_account_outcome_change(
        account_id: account.id,
        outcome_id: outcome.id
      )
    end

    it "successfully creates and executes the delayed job" do
      allow(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)

      progress = described_class.process_account_outcome_change(
        account_id: account.id,
        outcome_id: outcome.id
      )

      expect(progress).to be_queued
      expect(progress.delayed_job_id).to be_present

      run_jobs

      expect(progress.reload).to be_completed
      expect(Outcomes::CourseOutcomeRollupCalculationService).to have_received(:calculate_for_course_outcome)
        .at_least(:once)
    end
  end

  describe ".perform_rollup_calculation" do
    let(:progress) { double("progress") }

    it "creates orchestrator instance and calls it" do
      orchestrator = double("orchestrator")
      expect(described_class).to receive(:new).with(
        account_id: account.id,
        outcome_id: outcome.id,
        progress:
      ).and_return(orchestrator)
      expect(orchestrator).to receive(:call)

      described_class.perform_rollup_calculation(
        progress,
        account_id: account.id,
        outcome_id: outcome.id
      )
    end
  end

  describe "#initialize" do
    it "sets account and outcome from IDs" do
      orchestrator = described_class.new(account_id: account.id, outcome_id: outcome.id)
      expect(orchestrator.account).to eq(account)
      expect(orchestrator.outcome).to eq(outcome)
    end

    it "raises ArgumentError for invalid account_id" do
      expect do
        described_class.new(account_id: 99_999, outcome_id: outcome.id)
      end.to raise_error(ArgumentError, /Invalid account_id provided/)
    end

    it "raises ArgumentError for invalid outcome_id" do
      expect do
        described_class.new(account_id: account.id, outcome_id: 99_999)
      end.to raise_error(ArgumentError, /Invalid outcome_id provided/)
    end

    it "raises ArgumentError if outcome does not belong to account hierarchy" do
      other_account = account_model
      other_outcome = outcome_model(context: other_account)

      expect do
        described_class.new(account_id: account.id, outcome_id: other_outcome.id)
      end.to raise_error(ArgumentError, /does not belong to account/)
    end
  end

  describe "#call" do
    let(:progress) { double("progress", update!: nil, complete!: nil) }
    let(:orchestrator) { described_class.new(account_id: account.id, outcome_id: outcome.id, progress:) }

    context "when there are no affected courses" do
      before do
        course1.learning_outcome_links.where(content: outcome).destroy_all
        course2.learning_outcome_links.where(content: outcome).destroy_all
      end

      it "completes progress immediately" do
        expect(progress).to receive(:complete!)
        orchestrator.call
      end
    end

    context "when there are affected courses" do
      it "processes courses in batches and updates progress" do
        expect(progress).to receive(:update!).with(
          message: match(/Processing \d+ courses with outcome #{Regexp.escape(outcome.short_description)}/)
        )

        expect(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)
          .at_least(:once)

        expect(progress).to receive(:update!).with(
          completion: 100.0,
          message: match(%r{Processed \d+/\d+ courses \(100\.0%\)})
        )
        expect(progress).to receive(:complete!)

        orchestrator.call
      end

      it "continues processing other courses when one fails" do
        allow(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)
          .and_raise(StandardError.new("Test error"))

        expect(Canvas::Errors).to receive(:capture_exception).at_least(:once)
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect(progress).to receive(:complete!)

        orchestrator.call
      end
    end
  end

  describe "#find_affected_courses" do
    it "finds courses with outcome links in account hierarchy" do
      affected_courses = subject.send(:find_affected_courses)
      course_ids = affected_courses.pluck(:id)

      expect(course_ids).to include(course1.id)
      expect(course_ids).to include(course2.id)
      expect(course_ids).not_to include(course3.id)
    end

    it "includes courses from sub-accounts" do
      affected_courses = subject.send(:find_affected_courses)
      course_ids = affected_courses.pluck(:id)
      expect(course_ids).to include(course2.id)
    end

    it "only includes active courses" do
      course1.destroy
      affected_courses = subject.send(:find_affected_courses)
      course_ids = affected_courses.pluck(:id)
      expect(course_ids).not_to include(course1.id)
      expect(course_ids).to include(course2.id)
    end

    it "only includes active outcome links" do
      course1.learning_outcome_links.where(content: outcome).update_all(workflow_state: "deleted")
      affected_courses = subject.send(:find_affected_courses)
      course_ids = affected_courses.pluck(:id)
      expect(course_ids).not_to include(course1.id)
      expect(course_ids).to include(course2.id)
    end
  end

  describe "#process_course_batch" do
    let(:courses) { [course1, course2] }

    it "calls calculate_for_course_outcome for each course" do
      expect(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)
        .with(course_id: course1.id, outcome_id: outcome.id)
      expect(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)
        .with(course_id: course2.id, outcome_id: outcome.id)

      subject.send(:process_course_batch, courses)
    end

    it "handles exceptions for individual courses" do
      allow(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)
        .with(course_id: course1.id, outcome_id: outcome.id)
        .and_raise(StandardError.new("Test error"))

      expect(Canvas::Errors).to receive(:capture_exception).with(
        :account_outcome_rollup_orchestrator,
        instance_of(StandardError),
        {
          account_id: account.id,
          outcome_id: outcome.id,
          course_id: course1.id
        }
      )
      expect(Rails.logger).to receive(:error)

      expect(Outcomes::CourseOutcomeRollupCalculationService).to receive(:calculate_for_course_outcome)
        .with(course_id: course2.id, outcome_id: outcome.id)

      subject.send(:process_course_batch, courses)
    end
  end

  describe "#update_progress" do
    let(:progress) { double("progress") }
    let(:orchestrator) { described_class.new(account_id: account.id, outcome_id: outcome.id, progress:) }

    it "updates progress with correct completion percentage" do
      expect(progress).to receive(:update!).with(
        completion: 50.0,
        message: "Processed 5/10 courses (50.0%)"
      )

      orchestrator.send(:update_progress, 5, 10)
    end

    it "handles rounding correctly" do
      expect(progress).to receive(:update!).with(
        completion: 33.3,
        message: "Processed 1/3 courses (33.3%)"
      )

      orchestrator.send(:update_progress, 1, 3)
    end

    it "does nothing when progress is nil" do
      orchestrator_without_progress = described_class.new(account_id: account.id, outcome_id: outcome.id)
      expect { orchestrator_without_progress.send(:update_progress, 1, 3) }.not_to raise_error
    end
  end
end
