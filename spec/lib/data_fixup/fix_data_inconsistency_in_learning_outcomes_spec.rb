# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::FixDataInconsistencyInLearningOutcomes do
  before do
    shard = double("Shard")
    allow(Shard).to receive(:find).with(4).and_return(shard)
    allow(shard).to receive(:activate).and_yield
  end

  describe "learning outcomes" do
    it "updates the mastery_points and points_possible if they are strings" do
      learning_outcome = LearningOutcome.create!(
        short_description: "Short Description",
        data: { rubric_criterion: { mastery_points: "10.0", points_possible: "20.0" } }
      )
      expect { DataFixup::FixDataInconsistencyInLearningOutcomes.run }.to change {
        learning_outcome.reload.data[:rubric_criterion][:mastery_points]
      }.from("10.0").to(10.0).and change {
        learning_outcome.reload.data[:rubric_criterion][:points_possible]
      }.from("20.0").to(20.0)
    end

    it "ignores learning outcomes that already have numeric mastery_points and points_possible" do
      learning_outcome = LearningOutcome.create!(
        short_description: "Short Description",
        data: { rubric_criterion: { mastery_points: 10.0, points_possible: 20.0 } }
      )
      expect { DataFixup::FixDataInconsistencyInLearningOutcomes.run }.to not_change {
        learning_outcome.reload.data[:rubric_criterion][:mastery_points]
      }.from(10.0).and not_change {
        learning_outcome.reload.data[:rubric_criterion][:points_possible]
      }.from(20.0)
    end

    it "ignores learning outcomes without rubric_criterion" do
      learning_outcome = LearningOutcome.create!(short_description: "Short Description", data: {})
      expect { DataFixup::FixDataInconsistencyInLearningOutcomes.run }.not_to change(learning_outcome.reload, :data)
    end

    it "ignores learning outcomes with nil data" do
      learning_outcome = LearningOutcome.create!(short_description: "Short Description", data: nil)
      expect { DataFixup::FixDataInconsistencyInLearningOutcomes.run }.not_to change(learning_outcome.reload, :data)
    end
  end

  describe ".run" do
    it "activates the correct shard and guard rail" do
      shard = double("Shard")
      allow(Shard).to receive(:find).with(4).and_return(shard)
      allow(shard).to receive(:activate).and_yield

      expect(GuardRail).to receive(:activate).with(:secondary).and_yield
      expect(GuardRail).to receive(:activate).with(:primary).and_yield

      described_class.run
    end
  end
end
