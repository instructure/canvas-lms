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

describe Accessibility::CourseScanService do
  subject { described_class.new(course:) }

  let!(:course) { course_model }

  describe ".queue_scan_course" do
    it "creates a Progress record with the correct tag and context" do
      expect { described_class.queue_course_scan(course) }
        .to change { Progress.where(tag: "course_accessibility_scan", context: course).count }.by(1)
    end

    context "when a scan is already pending" do
      let!(:existing_progress) do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "queued")
      end

      it "returns the existing progress without creating a new one" do
        expect { described_class.queue_course_scan(course) }
          .not_to change { Progress.where(tag: "course_accessibility_scan", context: course).count }
        expect(described_class.queue_course_scan(course)).to eq(existing_progress)
      end
    end

    context "when a scan is already running" do
      let!(:existing_progress) do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "running")
      end

      it "returns the existing progress without creating a new one" do
        expect { described_class.queue_course_scan(course) }
          .not_to change { Progress.where(tag: "course_accessibility_scan", context: course).count }
        expect(described_class.queue_course_scan(course)).to eq(existing_progress)
      end
    end

    context "when a previous scan is completed" do
      before do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "completed")
      end

      it "creates a new progress" do
        expect { described_class.queue_course_scan(course) }
          .to change { Progress.where(tag: "course_accessibility_scan", context: course).count }.by(1)
      end
    end
  end

  describe ".scan" do
    let(:progress) do
      Progress.create!(tag: "course_accessibility_scan", context: course).tap(&:start!)
    end

    before do
      allow(Accessibility::ResourceScannerService).to receive(:call)
    end

    it "calls scan_course on a new service instance" do
      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(course:).and_return(service_instance)
      allow(service_instance).to receive(:scan_course)

      described_class.scan(progress)

      expect(service_instance).to have_received(:scan_course)
    end

    it "completes the progress" do
      described_class.scan(progress)
      expect(progress.reload).to be_completed
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(described_class).to receive(:scan_course).and_raise(StandardError, "Scan failed")
      end

      it "marks the progress as failed" do
        expect { described_class.scan(progress) }.to raise_error(StandardError, "Scan failed")
        expect(progress.reload).to be_failed
      end
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
  end
end
