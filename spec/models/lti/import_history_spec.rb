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

RSpec.describe Lti::ImportHistory do
  describe "validations" do
    let(:assignment) { assignment_model }

    it "validates presence of source_lti_id and target_lti_id" do
      ih = described_class.new(root_account: assignment.root_account)
      expect(ih).not_to be_valid
      expect(ih.errors[:source_lti_id]).to be_present
      expect(ih.errors[:target_lti_id]).to be_present

      ih.source_lti_id = "src1"
      ih.target_lti_id = "tgt1"
      expect(ih).to be_valid
    end
  end

  describe "root_account resolution" do
    let(:assignment) { assignment_model }

    it "sets root_account_id when provided" do
      row = described_class.create!(root_account: assignment.root_account, source_lti_id: "src1", target_lti_id: "tgt1")
      expect(row.root_account_id).to eq assignment.root_account_id
    end
  end

  describe "cache key helper" do
    let(:assignment) { assignment_model }

    it "builds expected cache key" do
      expect(described_class.import_history_cache_key(assignment.lti_context_id)).to eq ["lti_activity_id_history", assignment.lti_context_id].cache_key
    end
  end

  describe "cache clearing callbacks" do
    let(:assignment) { assignment_model }
    let(:target_lti_id) { "tgtA" }
    let(:cache_key) { described_class.import_history_cache_key(target_lti_id) }

    it "clears cache on create" do
      allow(Rails.cache).to receive(:delete).and_call_original
      described_class.create!(root_account: assignment.root_account, source_lti_id: "srcA", target_lti_id:)
      expect(Rails.cache).to have_received(:delete).with(cache_key)
    end

    it "clears cache on update" do
      row = described_class.create!(root_account: assignment.root_account, source_lti_id: "srcB", target_lti_id:)
      allow(Rails.cache).to receive(:delete).and_call_original
      row.update!(source_lti_id: "srcB2")
      expect(Rails.cache).to have_received(:delete).with(cache_key)
    end

    it "clears cache on destroy" do
      row = described_class.create!(root_account: assignment.root_account, source_lti_id: "srcC", target_lti_id:)
      allow(Rails.cache).to receive(:delete).and_call_original
      row.destroy!
      expect(Rails.cache).to have_received(:delete).with(cache_key)
    end
  end

  describe "db uniqueness constraint" do
    let(:assignment) { assignment_model }

    it "enforces uniqueness on target_lti_id,source_lti_id pair" do
      described_class.create!(root_account: assignment.root_account, source_lti_id: "src1", target_lti_id: "tgt1")
      expect do
        described_class.create!(root_account: assignment.root_account, source_lti_id: "src1", target_lti_id: "tgt1")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "recursive activity id history (for $Activity.id.history variable)" do
    let(:course) { course_model }
    let(:current_assignment) { assignment_model(context: course) }

    def edge(source, target, counter)
      Timecop.travel(Time.utc(2025, 1, counter)) do
        Lti::ImportHistory.create!(root_account: target.root_account, source_lti_id: source.lti_context_id, target_lti_id: target.lti_context_id)
      end
    end

    it "returns empty string when there is no import history for current assignment" do
      expect(Lti::ImportHistory.recursive_import_history(current_assignment.lti_context_id)).to eq([])
    end

    it "works for single level import" do
      a1 = assignment_model(context: course)

      # A1 -> Current
      edge(a1, current_assignment, 1)
      expect(Lti::ImportHistory.recursive_import_history(current_assignment.lti_context_id)).to eq([a1.lti_context_id])
    end

    it "works for multiple level, single chain import" do
      a1 = assignment_model(context: course)
      a2 = assignment_model(context: course)

      # A1 -> A2 -> Current
      edge(a1, a2, 1)
      edge(a2, current_assignment, 2)
      expect(Lti::ImportHistory.recursive_import_history(current_assignment.lti_context_id)).to eq([a2, a1].map(&:lti_context_id))
    end

    # I'm not sure how multi chain imports would happen in practice, but the code
    # should handle it.
    it "works for multiple level, multi chain import" do
      a1 = assignment_model(context: course)
      a2 = assignment_model(context: course)
      a3 = assignment_model(context: course)

      # A1 -> A2 -> Current
      # A3 -> A2
      edge(a1, a2, 1)
      edge(a2, current_assignment, 2)
      edge(a3, a2, 3)
      expect(Lti::ImportHistory.recursive_import_history(current_assignment.lti_context_id)).to eq([a2, a1, a3].map(&:lti_context_id))
    end

    it "works for multiple level, multi chain import with limit" do
      a1 = assignment_model(context: course)
      a2 = assignment_model(context: course)
      a3 = assignment_model(context: course)
      a4 = assignment_model(context: course)
      a5 = assignment_model(context: course)
      a6 = assignment_model(context: course)
      x = assignment_model(context: course)

      # X-> A1 -> A2 -> Current
      # A4 -> A3 -> A2
      # Unrelated: X -> A5
      # A6 -> current
      edge(a1, a2, 1)
      edge(x, a5, 1)
      edge(x, a1, 1)
      edge(a4, a3, 2)
      edge(a3, a2, 3)
      edge(a2, current_assignment, 4)
      edge(a6, current_assignment, 5)

      expect(Lti::ImportHistory.recursive_import_history(current_assignment.lti_context_id, limit: 4)).to eq([a2, a6, a1, a3].map(&:lti_context_id))
    end
  end

  describe "register" do
    it "creates a new history row for a previously unseen source id" do
      expect do
        Lti::ImportHistory.register(source_lti_id: "source", target_lti_id: "target", root_account: Account.default)
      end.to change { Lti::ImportHistory.where(target_lti_id: "target").count }.by(1)

      history = Lti::ImportHistory.where(target_lti_id: "target").first
      expect(history.source_lti_id).to eq "source"
      expect(history.target_lti_id).to eq "target"
    end

    it "does not create a duplicate history row when the edge already exists" do
      target_id = "target-dup"
      Lti::ImportHistory.register(source_lti_id: "source-1", target_lti_id: target_id, root_account: Account.default)
      expect do
        Lti::ImportHistory.register(source_lti_id: "source-1", target_lti_id: target_id, root_account: Account.default)
      end.not_to change { Lti::ImportHistory.where(target_lti_id: target_id).count }
    end

    it "creates multiple history rows for distinct source ids" do
      target_id = "target-multi"
      Lti::ImportHistory.register(source_lti_id: "source-1", target_lti_id: target_id, root_account: Account.default)
      Lti::ImportHistory.register(source_lti_id: "source-2", target_lti_id: target_id, root_account: Account.default)
      expect(Lti::ImportHistory.where(target_lti_id: target_id).pluck(:source_lti_id)).to match_array(%w[source-1 source-2])
    end
  end
end
