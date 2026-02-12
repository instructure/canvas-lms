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

require "spec_helper"

RSpec.describe PeerReview::DateOverrider do
  let(:test_class) do
    Class.new do
      include PeerReview::DateOverrider
    end
  end

  let(:test_instance) { test_class.new }
  let(:mock_override) { instance_double(AssignmentOverride) }

  describe "#apply_overridden_dates" do
    context "with all date fields present in override_params" do
      let(:due_at) { 2.days.from_now }
      let(:unlock_at) { 1.day.from_now }
      let(:lock_at) { 3.days.from_now }
      let(:override_params) do
        {
          due_at:,
          unlock_at:,
          lock_at:
        }
      end

      it "calls override_due_at when due_at is present" do
        expect(mock_override).to receive(:override_due_at).with(due_at)
        allow(mock_override).to receive(:override_unlock_at)
        allow(mock_override).to receive(:override_lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end

      it "calls override_unlock_at when unlock_at is present" do
        expect(mock_override).to receive(:override_unlock_at).with(unlock_at)
        allow(mock_override).to receive(:override_due_at)
        allow(mock_override).to receive(:override_lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end

      it "calls override_lock_at when lock_at is present" do
        expect(mock_override).to receive(:override_lock_at).with(lock_at)
        allow(mock_override).to receive(:override_due_at)
        allow(mock_override).to receive(:override_unlock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end

      it "calls all three override methods with the correct values" do
        expect(mock_override).to receive(:override_due_at).with(due_at)
        expect(mock_override).to receive(:override_unlock_at).with(unlock_at)
        expect(mock_override).to receive(:override_lock_at).with(lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end

    context "with only some date fields present in override_params" do
      let(:due_at) { 2.days.from_now }
      let(:override_params) do
        {
          due_at:,
          other_field: "some_value"
        }
      end

      it "only calls override methods for fields present in override_params" do
        expect(mock_override).to receive(:override_due_at).with(due_at)
        expect(mock_override).not_to receive(:override_unlock_at)
        expect(mock_override).not_to receive(:override_lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end

    context "with nil values in override_params" do
      let(:override_params) do
        {
          due_at: nil,
          unlock_at: nil,
          lock_at: nil
        }
      end

      it "calls override methods with nil values" do
        expect(mock_override).to receive(:override_due_at).with(nil)
        expect(mock_override).to receive(:override_unlock_at).with(nil)
        expect(mock_override).to receive(:override_lock_at).with(nil)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end

    context "with empty override_params" do
      let(:override_params) { {} }

      it "does not call any override methods" do
        expect(mock_override).not_to receive(:override_due_at)
        expect(mock_override).not_to receive(:override_unlock_at)
        expect(mock_override).not_to receive(:override_lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end

    context "with override_params containing non-date fields" do
      let(:due_at) { 1.day.from_now }
      let(:override_params) do
        {
          due_at:,
          title: "Some Title",
          description: "Some Description",
          points_possible: 100
        }
      end

      it "only processes date fields and ignores other fields" do
        expect(mock_override).to receive(:override_due_at).with(due_at)
        expect(mock_override).not_to receive(:override_unlock_at)
        expect(mock_override).not_to receive(:override_lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end

    context "with string keys in override_params" do
      let(:due_at) { 2.days.from_now }
      let(:override_params) do
        {
          "due_at" => due_at,
          "unlock_at" => nil
        }
      end

      it "does not call override methods for string keys" do
        expect(mock_override).not_to receive(:override_due_at)
        expect(mock_override).not_to receive(:override_unlock_at)
        expect(mock_override).not_to receive(:override_lock_at)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end

    context "edge cases with Time objects" do
      let(:past_time) { 1.day.ago }
      let(:current_time) { Time.current }
      let(:future_time) { Time.zone.parse("2030-12-31 23:59:59") }
      let(:override_params) do
        {
          due_at: past_time,
          unlock_at: future_time,
          lock_at: current_time
        }
      end

      it "handles various Time objects correctly" do
        expect(mock_override).to receive(:override_due_at).with(past_time)
        expect(mock_override).to receive(:override_unlock_at).with(future_time)
        expect(mock_override).to receive(:override_lock_at).with(current_time)

        test_instance.apply_overridden_dates(mock_override, override_params)
      end
    end
  end
end
