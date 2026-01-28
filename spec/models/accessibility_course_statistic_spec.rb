# frozen_string_literal: true

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

require_relative "../spec_helper"

RSpec.describe AccessibilityCourseStatistic do
  let(:account) { Account.default }
  let(:course) { course_factory(account:, active_all: true) }

  describe "associations" do
    it "belongs to a course" do
      stat = AccessibilityCourseStatistic.create!(
        course:,
        root_account: account
      )
      expect(stat.course).to eq(course)
    end

    it "resolves root_account through course" do
      stat = AccessibilityCourseStatistic.create!(course:)
      expect(stat.root_account).to eq(account)
    end
  end

  describe "workflow states" do
    it "has defined workflow states" do
      stat = AccessibilityCourseStatistic.create!(course:)

      valid_states = %w[initialized queued in_progress active failed deleted]
      valid_states.each do |state|
        stat.workflow_state = state
        expect(stat.save).to be_truthy, "expected #{state} to be a valid state"
      end
    end

    it "enforces valid workflow states at database level" do
      stat = AccessibilityCourseStatistic.create!(course:)
      expect do
        stat.update_column(:workflow_state, "invalid_state")
      end.to raise_error(ActiveRecord::StatementInvalid, /chk_workflow_state_enum/)
    end
  end

  describe "defaults" do
    it "sets default workflow_state to initialized" do
      stat = AccessibilityCourseStatistic.create!(course:)
      expect(stat.workflow_state).to eq("initialized")
    end

    it "sets default active_issue_count to nil" do
      stat = AccessibilityCourseStatistic.create!(course:)
      expect(stat.active_issue_count).to be_nil
    end

    it "sets default resolved_issue_count to nil" do
      stat = AccessibilityCourseStatistic.create!(course:)
      expect(stat.resolved_issue_count).to be_nil
    end
  end

  describe "required associations" do
    it "requires a course" do
      stat = AccessibilityCourseStatistic.new
      expect do
        stat.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /Course can't be blank/)
    end

    it "automatically resolves root_account from course" do
      stat = AccessibilityCourseStatistic.create!(course:)
      expect(stat.root_account_id).to eq(account.id)
    end
  end

  describe "workflow state transitions" do
    it "excludes deleted records from not_deleted scope" do
      stat1 = AccessibilityCourseStatistic.create!(course:)
      stat2 = AccessibilityCourseStatistic.create!(
        course: course_factory(account:)
      )

      stat1.update!(workflow_state: "deleted")

      expect(AccessibilityCourseStatistic.not_deleted).not_to include(stat1)
      expect(AccessibilityCourseStatistic.not_deleted).to include(stat2)
    end

    it "soft deletes record when destroy is called" do
      stat = AccessibilityCourseStatistic.create!(course:)
      stat_id = stat.id

      expect { stat.destroy }.not_to change { AccessibilityCourseStatistic.count }

      stat.reload
      expect(stat.workflow_state).to eq("deleted")
      expect(AccessibilityCourseStatistic.find(stat_id)).to eq(stat)
    end

    it "excludes soft-deleted records from default scope" do
      stat = AccessibilityCourseStatistic.create!(course:)

      stat.destroy

      expect(AccessibilityCourseStatistic.not_deleted).not_to include(stat)
      expect(AccessibilityCourseStatistic.where(id: stat.id).first).to eq(stat)
    end

    it "allows finding soft-deleted records with unscoped" do
      stat = AccessibilityCourseStatistic.create!(course:)
      stat_id = stat.id

      stat.destroy

      found_stat = AccessibilityCourseStatistic.unscoped.find(stat_id)
      expect(found_stat).to eq(stat)
      expect(found_stat.workflow_state).to eq("deleted")
    end
  end

  describe "creating statistics" do
    it "creates a valid statistic with required fields" do
      stat = AccessibilityCourseStatistic.create!(
        course:,
        active_issue_count: 5
      )

      expect(stat).to be_persisted
      expect(stat.course).to eq(course)
      expect(stat.root_account).to eq(account)
      expect(stat.active_issue_count).to eq(5)
      expect(stat.workflow_state).to eq("initialized")
    end

    it "can update workflow_state" do
      stat = AccessibilityCourseStatistic.create!(course:)

      stat.update!(workflow_state: "in_progress")
      expect(stat.reload.workflow_state).to eq("in_progress")

      stat.update!(workflow_state: "active")
      expect(stat.reload.workflow_state).to eq("active")
    end

    it "can update active_issue_count" do
      stat = AccessibilityCourseStatistic.create!(
        course:,
        active_issue_count: 10
      )

      expect(stat.active_issue_count).to eq(10)

      stat.update!(active_issue_count: 15)
      expect(stat.reload.active_issue_count).to eq(15)
    end

    it "can create with resolved_issue_count" do
      stat = AccessibilityCourseStatistic.create!(
        course:,
        resolved_issue_count: 3
      )

      expect(stat.resolved_issue_count).to eq(3)
    end

    it "can update resolved_issue_count" do
      stat = AccessibilityCourseStatistic.create!(
        course:,
        resolved_issue_count: 5
      )

      expect(stat.resolved_issue_count).to eq(5)

      stat.update!(resolved_issue_count: 8)
      expect(stat.reload.resolved_issue_count).to eq(8)
    end
  end

  describe "finding or creating statistics" do
    it "finds existing statistic for a course" do
      existing = AccessibilityCourseStatistic.create!(
        course:,
        active_issue_count: 5
      )

      found = AccessibilityCourseStatistic.find_or_create_by(course:)
      expect(found.id).to eq(existing.id)
      expect(found.active_issue_count).to eq(5)
    end

    it "creates new statistic if none exists" do
      expect do
        AccessibilityCourseStatistic.find_or_create_by(course:)
      end.to change { AccessibilityCourseStatistic.count }.by(1)
    end
  end

  describe "uniqueness" do
    it "prevents duplicate statistics for the same course" do
      AccessibilityCourseStatistic.create!(course:, active_issue_count: 5)

      duplicate = AccessibilityCourseStatistic.new(course:, active_issue_count: 10)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:course_id]).to be_present
    end

    it "enforces uniqueness at database level" do
      AccessibilityCourseStatistic.create!(course:, active_issue_count: 5)

      expect do
        # Try to bypass validation by manually setting IDs
        stat = AccessibilityCourseStatistic.new(active_issue_count: 10)
        stat.course_id = course.id
        stat.root_account_id = account.id
        stat.save(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows statistics for different courses" do
      course2 = course_factory(account:)

      stat1 = AccessibilityCourseStatistic.create!(course:, active_issue_count: 5)
      stat2 = AccessibilityCourseStatistic.create!(course: course2, active_issue_count: 10)

      expect(stat1).to be_persisted
      expect(stat2).to be_persisted
      expect(AccessibilityCourseStatistic.count).to eq(2)
    end
  end

  describe "#calculation_pending?" do
    let(:stat) { AccessibilityCourseStatistic.create!(course:) }

    context "when workflow_state is queued" do
      before { stat.update!(workflow_state: "queued") }

      it "returns true" do
        expect(stat.calculation_pending?).to be true
      end
    end

    context "when workflow_state is in_progress" do
      before { stat.update!(workflow_state: "in_progress") }

      it "returns true" do
        expect(stat.calculation_pending?).to be true
      end
    end

    context "when workflow_state is initialized" do
      before { stat.update!(workflow_state: "initialized") }

      it "returns false" do
        expect(stat.calculation_pending?).to be false
      end
    end

    context "when workflow_state is active" do
      before { stat.update!(workflow_state: "active") }

      it "returns false" do
        expect(stat.calculation_pending?).to be false
      end
    end

    context "when workflow_state is failed" do
      before { stat.update!(workflow_state: "failed") }

      it "returns false" do
        expect(stat.calculation_pending?).to be false
      end
    end

    context "when workflow_state is deleted" do
      before { stat.update!(workflow_state: "deleted") }

      it "returns false" do
        expect(stat.calculation_pending?).to be false
      end
    end
  end
end
