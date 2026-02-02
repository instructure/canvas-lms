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

require_relative "../../spec_helper"

describe Accessibility::SyllabusResource do
  let(:course) { course_model(syllabus_body: "<p>Course syllabus content</p>") }
  let(:syllabus_resource) { described_class.new(course) }

  describe "#initialize" do
    it "accepts a course" do
      expect(syllabus_resource.course).to eq(course)
    end
  end

  describe "AccessibilityCheckable interface" do
    describe "#scannable_content_column" do
      it "returns :syllabus_body" do
        expect(syllabus_resource.scannable_content_column).to eq(:syllabus_body)
      end
    end

    describe "#scannable_content" do
      it "returns the course syllabus_body via delegated method" do
        expect(syllabus_resource.scannable_content).to eq("<p>Course syllabus content</p>")
      end

      context "when syllabus_body is nil" do
        let(:course) { course_model(syllabus_body: nil) }

        it "returns nil" do
          expect(syllabus_resource.scannable_content).to be_nil
        end
      end
    end

    describe "#title" do
      it "returns 'Course Syllabus'" do
        expect(syllabus_resource.title).to eq("Course Syllabus")
      end
    end

    describe "#scannable_workflow_state" do
      it "returns the course's published state" do
        # Default course_model creates an unpublished course
        expect(syllabus_resource.scannable_workflow_state).to eq("unpublished")

        # When course is published
        course.workflow_state = "available"
        expect(syllabus_resource.scannable_workflow_state).to eq("published")
      end
    end

    describe "#scannable_content_size" do
      it "returns the size of the syllabus content" do
        expect(syllabus_resource.scannable_content_size).to eq(30)
      end
    end

    describe "#scannable_resource_tag" do
      it "returns the statsd tag for syllabus scanning" do
        expect(syllabus_resource.scannable_resource_tag).to eq("accessibility.syllabus_scanned")
      end
    end

    describe "#exceeds_accessibility_scan_limit?" do
      it "returns true when content exceeds limit" do
        expect(syllabus_resource.exceeds_accessibility_scan_limit?(10)).to be true
      end

      it "returns false when content is within limit" do
        expect(syllabus_resource.exceeds_accessibility_scan_limit?(100)).to be false
      end
    end

    describe "#scannable_content?" do
      it "returns true when syllabus has content" do
        expect(syllabus_resource.scannable_content?).to be true
      end

      context "when syllabus is empty" do
        let(:course) { course_model(syllabus_body: "") }

        it "returns false" do
          expect(syllabus_resource.scannable_content?).to be false
        end
      end
    end
  end

  describe "delegated methods" do
    it "delegates id to course" do
      expect(syllabus_resource.id).to eq(course.id)
    end

    it "delegates updated_at to course" do
      expect(syllabus_resource.updated_at).to eq(course.updated_at)
    end

    it "delegates account to course" do
      expect(syllabus_resource.account).to eq(course.account)
    end

    it "delegates global_id to course" do
      expect(syllabus_resource.global_id).to eq(course.global_id)
    end
  end

  describe "ActiveRecord-like interface" do
    describe "#resource_class_name" do
      it "returns 'Syllabus'" do
        expect(syllabus_resource.resource_class_name).to eq("Syllabus")
      end
    end
  end
end
