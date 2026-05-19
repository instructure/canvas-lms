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

describe Accessibility::CategoryBreakdownService do
  let(:course) { course_model }
  let(:other_course) { course_model }

  describe "#call" do
    context "with no course_ids" do
      it "returns an empty hash for an empty array" do
        expect(described_class.new(course_ids: []).call).to eq({})
      end

      it "returns an empty hash for nil" do
        expect(described_class.new(course_ids: nil).call).to eq({})
      end
    end

    context "with no issues" do
      it "returns an empty hash" do
        result = described_class.new(course_ids: [course.id]).call
        expect(result).to eq({})
      end
    end

    context "with issues spanning every category and workflow state" do
      before do
        accessibility_issue_model(course:, rule_type: "img-alt", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "img-alt-filename", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "img-alt-length", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "img-alt", workflow_state: "resolved")

        accessibility_issue_model(course:, rule_type: "adjacent-links", workflow_state: "dismissed")

        accessibility_issue_model(course:, rule_type: "headings-sequence", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "paragraphs-for-headings", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "headings-start-at-h2", workflow_state: "closed")

        accessibility_issue_model(course:, rule_type: "large-text-contrast", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "small-text-contrast", workflow_state: "resolved")

        accessibility_issue_model(course:, rule_type: "list-structure", workflow_state: "active")

        accessibility_issue_model(course:, rule_type: "table-caption", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "table-header", workflow_state: "dismissed")
        accessibility_issue_model(course:, rule_type: "table-header-scope", workflow_state: "closed")
      end

      it "rolls all rule_types into their category buckets" do
        result = described_class.new(course_ids: [course.id]).call

        expect(result[course.id][:images]).to eq(active: 3, resolved: 1)
        expect(result[course.id][:links]).to eq(dismissed: 1)
        expect(result[course.id][:headers]).to eq(active: 2, closed: 1)
        expect(result[course.id][:contrast]).to eq(active: 1, resolved: 1)
        expect(result[course.id][:lists]).to eq(active: 1)
        expect(result[course.id][:tables]).to eq(active: 1, dismissed: 1, closed: 1)
      end

      it "returns all four workflow states where they appear" do
        result = described_class.new(course_ids: [course.id]).call
        states_seen = result[course.id].values.flat_map(&:keys).uniq.sort
        expect(states_seen).to eq(%i[active closed dismissed resolved])
      end
    end

    context "with issues in multiple courses" do
      before do
        accessibility_issue_model(course:, rule_type: "img-alt", workflow_state: "active")
        accessibility_issue_model(course: other_course, rule_type: "img-alt", workflow_state: "active")
        accessibility_issue_model(course: other_course, rule_type: "table-caption", workflow_state: "resolved")
      end

      it "keys the rollup by course_id" do
        result = described_class.new(course_ids: [course.id, other_course.id]).call

        expect(result.keys).to contain_exactly(course.id, other_course.id)
        expect(result[course.id][:images][:active]).to eq(1)
        expect(result[other_course.id][:images][:active]).to eq(1)
        expect(result[other_course.id][:tables][:resolved]).to eq(1)
      end

      it "ignores courses not in course_ids" do
        result = described_class.new(course_ids: [course.id]).call
        expect(result.keys).to eq([course.id])
      end
    end

    context "with an unknown rule_type in the aggregation result" do
      # A DB check constraint blocks persisting unknown rule_types, so we
      # stub Rule.category_for to simulate registry/DB drift.
      it "logs a warning and drops the row rather than raising" do
        accessibility_issue_model(course:, rule_type: "img-alt", workflow_state: "active")
        allow(Accessibility::Rule).to receive(:category_for).with("img-alt").and_return(nil)

        expect(Rails.logger).to receive(:warn).with(/img-alt/)
        result = described_class.new(course_ids: [course.id]).call
        expect(result).to eq({})
      end

      it "does not raise when mixed with known rule_types" do
        accessibility_issue_model(course:, rule_type: "img-alt", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "list-structure", workflow_state: "active")
        accessibility_issue_model(course:, rule_type: "list-structure", workflow_state: "active")
        allow(Accessibility::Rule).to receive(:category_for).and_call_original
        allow(Accessibility::Rule).to receive(:category_for).with("img-alt").and_return(nil)
        allow(Rails.logger).to receive(:warn)

        result = described_class.new(course_ids: [course.id]).call
        expect(result[course.id][:lists][:active]).to eq(2)
        expect(result[course.id].keys).not_to include(nil)
      end
    end
  end
end
