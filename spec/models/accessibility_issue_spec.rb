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

    describe "is_syllabus_or_context" do
      let(:course) { course_model }
      let(:wiki_page) { wiki_page_model(course:) }

      context "when is_syllabus is true and context is present" do
        before do
          subject.course = course
          subject.is_syllabus = true
          subject.wiki_page = wiki_page
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include("is_syllabus and context must be mutually exclusive")
        end
      end

      context "when is_syllabus is true and context is nil" do
        before do
          subject.course = course
          subject.is_syllabus = true
          subject.rule_type = Accessibility::Rules::ImgAltRule.id
        end

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "when is_syllabus is false and context is present" do
        before do
          subject.course = course
          subject.is_syllabus = false
          subject.wiki_page = wiki_page
          subject.rule_type = Accessibility::Rules::ImgAltRule.id
        end

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "when is_syllabus is false and context is nil" do
        before do
          subject.course = course
          subject.is_syllabus = false
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include("is_syllabus and context must be mutually exclusive")
        end
      end
    end
  end

  describe "#allow_nil_param_value?" do
    let(:course) { course_model }

    context "when rule type is in the allowed list" do
      subject do
        described_class.new(
          course:,
          rule_type: "allowed-rule"
        )
      end

      before do
        allow(Accessibility::Rules::ImgAltRule).to receive(:id).and_return("allowed-rule")
      end

      it "returns true" do
        expect(subject.allow_nil_param_value?).to be true
      end
    end

    context "when rule type is not in the allowed list" do
      subject do
        described_class.new(
          course:,
          rule_type: "not-allowed-rule"
        )
      end

      it "returns false" do
        expect(subject.allow_nil_param_value?).to be false
      end
    end
  end
end
