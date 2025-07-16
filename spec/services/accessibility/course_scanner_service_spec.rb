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

    context "when scanning PDF attachments" do
      let!(:attachment1) { attachment_model(course:, content_type: "application/pdf") }
      let!(:attachment2) { attachment_model(course:, content_type: "application/pdf") }
      let!(:attachment3) { attachment_model(course:, content_type: "text/plain") }

      before do
        attachment2.destroy!
        subject.scan_course
      end

      it "scans the active PDF attachment" do
        expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: attachment1)
      end

      it "does not scan the deleted PDF attachment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: attachment2)
      end

      it "does not scan attachments with invalid content type" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: attachment3)
      end
    end
  end
end
