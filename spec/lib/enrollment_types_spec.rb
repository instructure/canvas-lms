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
#

require "spec_helper"

describe EnrollmentTypes do
  describe ".definitions" do
    it "returns enrollment type definitions" do
      definitions = EnrollmentTypes.definitions
      expect(definitions).to be_a(Hash)
      expect(definitions).to have_key("StudentEnrollment")
      expect(definitions).to have_key("TeacherEnrollment")
      expect(definitions).to have_key("TaEnrollment")
      expect(definitions).to have_key("DesignerEnrollment")
      expect(definitions).to have_key("ObserverEnrollment")
    end

    it "includes required fields for each enrollment type" do
      definitions = EnrollmentTypes.definitions
      definitions.each_value do |definition|
        expect(definition).to have_key(:base_role_name)
        expect(definition).to have_key(:name)
        expect(definition).to have_key(:label)
        expect(definition).to have_key(:plural_label)
        expect(definition[:label]).to respond_to(:call)
        expect(definition[:plural_label]).to respond_to(:call)
      end
    end
  end

  describe ".labels" do
    let(:account) { account_model }

    context "without Canvas Career overrides" do
      before do
        allow(CanvasCareer::LabelOverrides).to receive(:enrollment_type_overrides).and_return({})
      end

      it "returns original enrollment type labels" do
        labels = EnrollmentTypes.labels(account)
        expect(labels).to be_an(Array)
        expect(labels.length).to eq(5)

        student_enrollment = labels.find { |l| l[:name] == "StudentEnrollment" }
        expect(student_enrollment[:label].call).to eq("Student")
        expect(student_enrollment[:plural_label].call).to eq("Students")
      end
    end

    context "with Canvas Career overrides" do
      before do
        overrides = {
          "StudentEnrollment" => {
            label: -> { "Learner" },
            plural_label: -> { "Learners" }
          },
          "TeacherEnrollment" => {
            label: -> { "Instructor" },
            plural_label: -> { "Instructors" }
          }
        }
        allow(CanvasCareer::LabelOverrides).to receive(:enrollment_type_overrides).and_return(overrides)
      end

      it "applies Canvas Career overrides" do
        labels = EnrollmentTypes.labels(account)

        student_enrollment = labels.find { |l| l[:name] == "StudentEnrollment" }
        expect(student_enrollment[:label].call).to eq("Learner")
        expect(student_enrollment[:plural_label].call).to eq("Learners")

        teacher_enrollment = labels.find { |l| l[:name] == "TeacherEnrollment" }
        expect(teacher_enrollment[:label].call).to eq("Instructor")
        expect(teacher_enrollment[:plural_label].call).to eq("Instructors")
      end

      it "preserves original labels for non-overridden types" do
        labels = EnrollmentTypes.labels(account)

        ta_enrollment = labels.find { |l| l[:name] == "TaEnrollment" }
        expect(ta_enrollment[:label].call).to eq("TA")
        expect(ta_enrollment[:plural_label].call).to eq("TAs")
      end

      it "handles partial overrides" do
        overrides = {
          "StudentEnrollment" => {
            label: -> { "Learner" }
            # No plural_label override
          }
        }
        allow(CanvasCareer::LabelOverrides).to receive(:enrollment_type_overrides).and_return(overrides)

        labels = EnrollmentTypes.labels(account)
        student_enrollment = labels.find { |l| l[:name] == "StudentEnrollment" }
        expect(student_enrollment[:label].call).to eq("Learner")
        expect(student_enrollment[:plural_label].call).to eq("Students") # Original
      end
    end

    context "without context" do
      it "returns original labels when context is nil" do
        labels = EnrollmentTypes.labels(nil)
        expect(labels).to be_an(Array)

        student_enrollment = labels.find { |l| l[:name] == "StudentEnrollment" }
        expect(student_enrollment[:label].call).to eq("Student")
      end
    end
  end
end
