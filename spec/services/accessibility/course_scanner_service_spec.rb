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

describe Accessibility::CourseScannerService do
  subject { described_class.new(course:) }

  let!(:course) { course_model }

  describe "#call" do
    let(:delay_mock) { double("delay") }

    before do
      allow(subject).to receive(:delay).and_return(delay_mock)
      allow(delay_mock).to receive(:scan_course)
    end

    it "enqueues a delayed job for scanning the course" do
      expect(subject).to receive(:delay)
        .with(singleton: "accessibility_scan_course_#{course.global_id}")
        .and_return(delay_mock)
      expect(delay_mock).to receive(:scan_course)

      subject.call
    end
  end

  describe "#scan_course" do
    before do
      allow(Accessibility::ResourceScannerService).to receive(:call)
    end

    context "when the course exceeds the accessibility scan size limit" do
      before do
        allow_any_instance_of(Course).to receive(:exceeds_accessibility_scan_limit?).and_return(true)
        wiki_page_model(course:)
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(
          "[A11Y Scan] Skipped scanning the course #{course.name} (ID: #{course.id}) due to exceeding the size limit."
        )

        subject.scan_course
      end

      it "does not scan resources" do
        expect(Accessibility::ResourceScannerService).not_to receive(:call)

        subject.scan_course
      end
    end

    context "when scanning wiki pages" do
      let!(:wiki_page1) { wiki_page_model(course:) }
      let!(:wiki_page2) { wiki_page_model(course:) }

      before do
        wiki_page2.destroy!
        subject.scan_course
      end

      it "scans the active wiki page" do
        expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: wiki_page1)
      end

      it "does not scan the deleted wiki page" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: wiki_page2)
      end
    end

    context "when scanning assignments" do
      let!(:assignment1) { assignment_model(course:) }
      let!(:assignment2) { assignment_model(course:) }

      before do
        assignment2.destroy!
        subject.scan_course
      end

      it "scans the active assignment" do
        expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: assignment1)
      end

      it "does not scan the deleted assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: assignment2)
      end
    end
  end
end
