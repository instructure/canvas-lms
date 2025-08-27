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

describe AccessibilityIssue do
  subject { described_class.new }

  it_behaves_like "it has a single accessibility context"

  describe "defaults" do
    it "sets the default workflow_state to active" do
      expect(subject.workflow_state).to eq "active"
    end
  end

  describe "factories" do
    it "has a valid factory" do
      expect(accessibility_issue_model).to be_valid
    end
  end

  describe "scopes" do
    describe ".for_context" do
      context "when context is valid" do
        let(:wiki_page) { wiki_page_model }
        let(:subject_for_context) { accessibility_issue_model(context: wiki_page) }

        it "returns the correct record" do
          expect(described_class.for_context(wiki_page)).to contain_exactly(subject_for_context)
        end
      end

      context "when context is not valid" do
        let(:invalid_context) { double("InvalidContext", id: 1) }

        it "raises an error" do
          expect { described_class.for_context(invalid_context) }.to(
            raise_error(ArgumentError, "Unsupported context type: RSpec::Mocks::Double")
          )
        end
      end
    end
  end

  describe "validations" do
    context "when course is missing" do
      before { subject.course = nil }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:course]).to include("can't be blank")
      end
    end

    describe "workflow_state" do
      context "when workflow_state is missing" do
        before { subject.workflow_state = nil }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:workflow_state]).to include("can't be blank")
        end
      end

      context "when workflow_state is not in the allowed list" do
        before { subject.workflow_state = "invalid_state" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:workflow_state]).to include("is not included in the list")
        end
      end
    end

    describe "rule_type" do
      context "when rule_type is missing" do
        before { subject.rule_type = nil }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:rule_type]).to include("can't be blank")
        end
      end

      context "when rule_type is not in the registry" do
        before { subject.rule_type = "invalid_rule" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:rule_type]).to include("is not included in the list")
        end
      end
    end
  end
end
