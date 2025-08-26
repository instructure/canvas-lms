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

describe Accessibility::RootAccountScannerService do
  subject { described_class.new(account: root_account) }

  let(:root_account) { account_model }

  describe "#call" do
    let(:course) { course_model(root_account:) }
    let(:delay_mock) { instance_double(described_class) }

    before do
      allow(subject).to receive(:delay).and_return(delay_mock)
      allow(delay_mock).to receive(:scan_account)
    end

    it "enqueues a delayed job for scanning the account" do
      expect(subject).to receive(:delay)
        .with(singleton: "accessibility_scan_account_#{root_account.global_id}")
        .and_return(delay_mock)
      expect(delay_mock).to receive(:scan_account)

      subject.call
    end
  end

  describe "#scan_account" do
    before do
      allow(Accessibility::CourseScannerService).to receive(:call)
    end

    context "when scanning a root account" do
      context "when the account has less courses than the scan limit" do
        let!(:active_course) { course_model(root_account:) }
        let!(:completed_course) { course_model(root_account:, workflow_state: "completed") }
        let!(:deleted_course) { course_model(root_account:) }

        before do
          deleted_course.destroy!
          subject.scan_account
        end

        it "scans the active courses" do
          expect(Accessibility::CourseScannerService).to have_received(:call).with(course: active_course)
        end

        it "does not scan the deleted courses" do
          expect(Accessibility::CourseScannerService).not_to have_received(:call).with(course: deleted_course)
        end

        it "does not scan the completed courses" do
          expect(Accessibility::CourseScannerService).not_to have_received(:call).with(course: completed_course)
        end
      end

      context "when the account has more courses than the scan limit" do
        let(:course_ids) { (1..1050).to_a }
        let(:mock_course_scope) { instance_double("ActiveRecord::Relation") }
        let(:max_course_count) { 10 }
        let(:created_course_count) { 15 }

        before do
          # override the MAX_COURSE_COUNT constant to enable faster test execution
          stub_const("Accessibility::RootAccountScannerService::MAX_COURSE_COUNT", max_course_count)
          created_course_count.times { course_model(root_account:) }
        end

        it "limits the courses to scan" do
          subject.scan_account

          expect(Accessibility::CourseScannerService).to have_received(:call).exactly(max_course_count).times
        end

        it "only scans the most recently updated courses" do
          scanned_courses = []
          allow(Accessibility::CourseScannerService).to receive(:call) do |args|
            scanned_courses << args[:course]
          end
          subject.scan_account
          scanned_course_ids = scanned_courses.map(&:id)
          most_recent_course_ids = root_account.all_courses.order(id: :desc).limit(max_course_count).pluck(:id)

          expect(scanned_course_ids).to match_array(most_recent_course_ids)
        end
      end
    end

    context "when scanning a non-root account" do
      before do
        allow(root_account).to receive(:root_account?).and_return(false)
      end

      it "logs a warning and returns without scanning" do
        expect(Rails.logger).to receive(:warn).with(
          "[A11Y Scan] Failed to scan account #{@account.global_id}: account must be a root account."
        )

        subject.scan_account
      end

      it "returns without scanning" do
        expect(root_account).not_to receive(:all_courses)

        subject.scan_account
      end
    end
  end
end
