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

require_relative "../../../spec_helper"

class AvailabilityStatusHarness
  include Api::V1::AvailabilityStatus
end

describe Api::V1::AvailabilityStatus do
  let(:harness) { AvailabilityStatusHarness.new }

  describe "#calculate_availability_status" do
    context "when unlock_at is in the future" do
      it "returns pending status with the unlock date" do
        unlock_at = 5.days.from_now
        lock_at = 10.days.from_now

        result = harness.calculate_availability_status(unlock_at, lock_at)

        expect(result[:status]).to eq("pending")
        expect(result[:date]).to eq(unlock_at)
      end

      it "returns pending status even without lock_at" do
        unlock_at = 5.days.from_now

        result = harness.calculate_availability_status(unlock_at, nil)

        expect(result[:status]).to eq("pending")
        expect(result[:date]).to eq(unlock_at)
      end
    end

    context "when lock_at is in the past" do
      it "returns closed status with nil date" do
        unlock_at = 10.days.ago
        lock_at = 5.days.ago

        result = harness.calculate_availability_status(unlock_at, lock_at)

        expect(result[:status]).to eq("closed")
        expect(result[:date]).to be_nil
      end

      it "returns closed status even without unlock_at" do
        lock_at = 5.days.ago

        result = harness.calculate_availability_status(nil, lock_at)

        expect(result[:status]).to eq("closed")
        expect(result[:date]).to be_nil
      end
    end

    context "when currently available with future lock_at" do
      it "returns open status with the lock date" do
        unlock_at = 5.days.ago
        lock_at = 5.days.from_now

        result = harness.calculate_availability_status(unlock_at, lock_at)

        expect(result[:status]).to eq("open")
        expect(result[:date]).to eq(lock_at)
      end

      it "returns open status when unlock_at is nil and lock_at is in the future" do
        lock_at = 5.days.from_now

        result = harness.calculate_availability_status(nil, lock_at)

        expect(result[:status]).to eq("open")
        expect(result[:date]).to eq(lock_at)
      end
    end

    context "when no restrictions" do
      it "returns nil status when both dates are nil" do
        result = harness.calculate_availability_status(nil, nil)

        expect(result[:status]).to be_nil
        expect(result[:date]).to be_nil
      end

      it "returns nil status when unlock_at is in the past and lock_at is nil" do
        unlock_at = 5.days.ago

        result = harness.calculate_availability_status(unlock_at, nil)

        expect(result[:status]).to be_nil
        expect(result[:date]).to be_nil
      end
    end

    context "edge cases" do
      it "treats exact current time as unlocked for unlock_at" do
        current_time = Time.zone.now
        lock_at = 5.days.from_now

        result = harness.calculate_availability_status(current_time, lock_at)

        expect(result[:status]).to eq("open")
      end

      it "treats exact current time as locked for lock_at" do
        unlock_at = 5.days.ago
        current_time = Time.zone.now

        result = harness.calculate_availability_status(unlock_at, current_time)

        expect(result[:status]).to eq("closed")
      end
    end
  end
end
