# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Accessibility::CourseStatisticCalculatorService do
  let(:account) { Account.default }
  let(:course) { course_model(account:) }

  describe ".queue_calculation" do
    it "creates an AccessibilityCourseStatistic if none exists" do
      expect { described_class.queue_calculation(course) }
        .to change { AccessibilityCourseStatistic.count }.by(1)
    end

    it "finds existing AccessibilityCourseStatistic" do
      existing = AccessibilityCourseStatistic.create!(course:)

      expect { described_class.queue_calculation(course) }
        .not_to change { AccessibilityCourseStatistic.count }

      result = described_class.queue_calculation(course)
      expect(result.id).to eq(existing.id)
    end

    it "updates workflow_state to queued" do
      statistic = described_class.queue_calculation(course)
      expect(statistic.workflow_state).to eq("queued")
    end

    it "enqueues a delayed job with correct parameters" do
      expect(described_class).to receive(:delay) do |args|
        expect(args[:n_strand]).to eq(["accessibility_course_statistics", course.account.global_id])
        expect(args[:singleton]).to eq("accessibility_course_statistics_#{course.global_id}")
        expect(args[:run_at]).to be_within(1.second).of(described_class.calculation_delay.from_now)
        described_class
      end

      expect(described_class).to receive(:perform_calculation)

      described_class.queue_calculation(course)
    end

    it "returns the statistic" do
      result = described_class.queue_calculation(course)
      expect(result).to be_a(AccessibilityCourseStatistic)
      expect(result.course).to eq(course)
    end

    context "when calculation is already queued" do
      let!(:statistic) do
        AccessibilityCourseStatistic.create!(course:, workflow_state: "queued")
      end

      it "does not update workflow_state" do
        expect { described_class.queue_calculation(course) }
          .not_to(change { statistic.reload.workflow_state })
      end

      it "does not enqueue a new job" do
        expect(described_class).not_to receive(:delay)
        described_class.queue_calculation(course)
      end

      it "returns the existing statistic" do
        result = described_class.queue_calculation(course)
        expect(result.id).to eq(statistic.id)
      end
    end

    context "when calculation is in progress" do
      let!(:statistic) do
        AccessibilityCourseStatistic.create!(course:, workflow_state: "in_progress")
      end

      it "does not update workflow_state" do
        expect { described_class.queue_calculation(course) }
          .not_to(change { statistic.reload.workflow_state })
      end

      it "does not enqueue a new job" do
        expect(described_class).not_to receive(:delay)
        described_class.queue_calculation(course)
      end

      it "returns the existing statistic" do
        result = described_class.queue_calculation(course)
        expect(result.id).to eq(statistic.id)
      end
    end

    context "when previous calculation is completed" do
      let!(:statistic) do
        AccessibilityCourseStatistic.create!(course:, workflow_state: "active")
      end

      it "updates workflow_state to queued" do
        described_class.queue_calculation(course)
        expect(statistic.reload.workflow_state).to eq("queued")
      end

      it "enqueues a new job" do
        expect(described_class).to receive(:delay).and_return(described_class)
        expect(described_class).to receive(:perform_calculation)
        described_class.queue_calculation(course)
      end
    end

    context "when previous calculation failed" do
      let!(:statistic) do
        AccessibilityCourseStatistic.create!(course:, workflow_state: "failed")
      end

      it "updates workflow_state to queued" do
        described_class.queue_calculation(course)
        expect(statistic.reload.workflow_state).to eq("queued")
      end

      it "enqueues a new job" do
        expect(described_class).to receive(:delay).and_return(described_class)
        expect(described_class).to receive(:perform_calculation)
        described_class.queue_calculation(course)
      end
    end
  end

  describe ".perform_calculation" do
    let!(:statistic) { AccessibilityCourseStatistic.create!(course:) }

    it "finds the statistic by id" do
      expect(AccessibilityCourseStatistic).to receive(:find).with(statistic.id).and_call_original
      described_class.perform_calculation(statistic.id)
    end

    it "updates workflow_state to in_progress then active" do
      described_class.perform_calculation(statistic.id)

      statistic.reload
      expect(statistic.workflow_state).to eq("active")
    end
  end

  describe "#calculate" do
    let(:statistic) { AccessibilityCourseStatistic.create!(course:) }
    let(:service) { described_class.new(statistic:) }

    it "updates workflow_state to active on success" do
      service.calculate
      expect(statistic.reload.workflow_state).to eq("active")
    end

    it "calls ActiveIssueCalculator to set active issue count" do
      counter = instance_double(Accessibility::ActiveIssueCalculator)
      expect(Accessibility::ActiveIssueCalculator).to receive(:new).with(statistic:).and_return(counter)
      expect(counter).to receive(:calculate)
      service.calculate
    end

    context "when there are active issues in the course" do
      before do
        5.times { accessibility_issue_model(course:, workflow_state: "active") }
        2.times { accessibility_issue_model(course:, workflow_state: "resolved") }
      end

      it "sets active_issue_count to the correct value" do
        service.calculate
        expect(statistic.reload.active_issue_count).to eq(5)
      end
    end

    context "when there are no active issues" do
      before do
        3.times { accessibility_issue_model(course:, workflow_state: "resolved") }
      end

      it "sets active_issue_count to 0" do
        service.calculate
        expect(statistic.reload.active_issue_count).to eq(0)
      end
    end

    context "when an error occurs" do
      before do
        call_count = 0
        allow(statistic).to receive(:update!) do |args|
          call_count += 1
          if call_count == 1 && args[:workflow_state] == "in_progress"
            statistic.workflow_state = "in_progress"
            statistic.save!(validate: false)
          elsif call_count == 2 && args[:workflow_state] == "active"
            raise StandardError, "Calculation failed"
          else
            statistic.update_column(:workflow_state, args[:workflow_state])
          end
        end
      end

      it "updates workflow_state to failed" do
        expect { service.calculate }.to raise_error(StandardError, "Calculation failed")
        expect(statistic.reload.workflow_state).to eq("failed")
      end

      it "logs an error report" do
        error_report = instance_double("ErrorReport", id: 12_345)
        expect(ErrorReport).to receive(:log_exception).with(
          "accessibility_course_statistics",
          kind_of(StandardError),
          hash_including(
            statistic_id: statistic.global_id,
            course_id: course.id,
            course_name: course.name
          )
        ).and_return(error_report)

        expect { service.calculate }.to raise_error(StandardError)
      end

      it "captures the exception in Sentry" do
        expect(Sentry).to receive(:with_scope)
        expect { service.calculate }.to raise_error(StandardError)
      end

      it "re-raises the error" do
        expect { service.calculate }.to raise_error(StandardError, "Calculation failed")
      end
    end
  end

  describe ".calculation_delay" do
    it "returns default delay of 5 minutes" do
      expect(described_class.calculation_delay).to eq(5.minutes)
    end

    it "can be overridden via Setting" do
      allow(Setting).to receive(:get).with("accessibility_course_statistics_calculation_delay", "300").and_return("600")
      expect(described_class.calculation_delay).to eq(10.minutes)
    end

    it "converts setting value to seconds" do
      allow(Setting).to receive(:get).with("accessibility_course_statistics_calculation_delay", "300").and_return("120")
      expect(described_class.calculation_delay).to eq(2.minutes)
    end
  end
end
