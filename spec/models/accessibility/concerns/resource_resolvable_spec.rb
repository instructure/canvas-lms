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

describe Accessibility::Concerns::ResourceResolvable do
  let(:course) { course_model }
  let(:wiki_page) { wiki_page_model(course:) }

  describe "when included in AccessibilityResourceScan" do
    context "for a regular resource" do
      let(:scan) do
        accessibility_resource_scan_model(
          course:,
          context: wiki_page,
          resource_name: "Test Page"
        )
      end

      describe "#resource" do
        it "returns the context" do
          expect(scan.resource).to eq(wiki_page)
        end

        it "memoizes the result" do
          resource1 = scan.resource
          resource2 = scan.resource
          expect(resource1).to be(resource2)
        end
      end
    end

    context "for a syllabus resource" do
      let(:scan) do
        course.update!(syllabus_body: "<p>Syllabus content</p>")
        AccessibilityResourceScan.create!(
          course:,
          is_syllabus: true,
          resource_name: "Course Syllabus",
          workflow_state: "completed",
          resource_workflow_state: "published",
          issue_count: 0
        )
      end

      describe "#resource" do
        it "returns a SyllabusResource wrapper" do
          expect(scan.resource).to be_a(Accessibility::SyllabusResource)
        end

        it "wraps the correct course" do
          expect(scan.resource.course).to eq(course)
        end
      end
    end
  end
end
