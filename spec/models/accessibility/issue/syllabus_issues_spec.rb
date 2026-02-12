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

require_relative "../../../spec_helper"

describe Accessibility::Issue::SyllabusIssues do
  before do
    course_with_teacher(active_all: true)
  end

  let(:issue) { Accessibility::Issue.new(context: @course) }

  describe "#generate_syllabus_resources" do
    context "when course has no syllabus" do
      before do
        @course.update!(syllabus_body: nil)
      end

      it "returns an empty hash" do
        result = issue.generate_syllabus_resources
        expect(result).to eq({})
      end
    end

    context "when course has a syllabus" do
      before do
        @course.update!(syllabus_body: "<p>Course syllabus content</p>")
      end

      context "with skip_scan: true" do
        it "returns syllabus attributes without scanning" do
          result = issue.generate_syllabus_resources(skip_scan: true)
          expect(result).to include(
            title: "Syllabus",
            published: true,
            updated_at: be_a(String)
          )
          expect(result).to include(:url, :edit_url)
        end
      end

      context "with skip_scan: false" do
        it "scans the syllabus for accessibility issues" do
          result = issue.generate_syllabus_resources(skip_scan: false)
          expect(result).to have_key(:syllabus)
          expect(result[:syllabus]).to include(
            title: "Syllabus",
            published: true,
            count: be_a(Integer),
            severity: be_a(String),
            issues: be_a(Array)
          )
        end
      end

      context "with accessibility issues in syllabus" do
        before do
          @course.update!(syllabus_body: '<img src="test.jpg" />')
        end

        it "detects accessibility issues" do
          result = issue.generate_syllabus_resources(skip_scan: false)
          expect(result[:syllabus][:count]).to be > 0
          expect(result[:syllabus][:severity]).not_to eq("none")
          expect(result[:syllabus][:issues]).not_to be_empty
        end
      end
    end

    context "when course is unpublished" do
      before do
        @course.update!(
          workflow_state: "created",
          syllabus_body: "<p>Draft syllabus</p>"
        )
      end

      it "marks syllabus as unpublished" do
        result = issue.generate_syllabus_resources(skip_scan: true)
        expect(result[:published]).to be_falsey
      end
    end
  end

  describe "resource URLs" do
    before do
      @course.update!(syllabus_body: "<p>Test</p>")
    end

    it "generates correct URLs for syllabus" do
      result = issue.generate_syllabus_resources(skip_scan: true)
      expect(result[:url]).to eq("/courses/#{@course.id}/syllabus")
      expect(result[:edit_url]).to eq("/courses/#{@course.id}/syllabus/edit")
    end
  end
end
