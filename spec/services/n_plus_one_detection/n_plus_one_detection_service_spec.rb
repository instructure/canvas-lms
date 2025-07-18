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

describe NPlusOneDetection::NPlusOneDetectionService do
  describe ".call" do
    let(:service) { NPlusOneDetection::NPlusOneDetectionService }
    let(:user) { site_admin_user }
    let(:source_name) { "courses#index" }
    let(:attachment) { user.attachments.last }
    let(:report_content) { attachment.open.read }

    it "creates an attachment with a plain text N+1 detection report" do
      expect do
        service.call(user:, source_name:, custom_name: "custom-label") do
          # Simulate some operation that doesn't trigger N+1 queries
          User.first
        end
      end.to change { user.attachments.count }.by(1)

      aggregate_failures do
        expect(attachment.display_name).to match(/^n_plus_one_detection-custom-label-courses#index-.+$/)
        expect(attachment.filename).to match(/^n_plus_one_detection-custom-label-courses#index-.+\.txt$/)
        expect(attachment.content_type).to eql "text/plain"
        expect(attachment.root_account).to eql Account.site_admin
        expect(attachment.folder).to eql user.n_plus_one_detection_folder
      end
    end

    it "creates an attachment with error information if an error occurs during N+1 detection" do
      service.call(user:, source_name:) { raise "Bad news bears" }

      aggregate_failures do
        expect(attachment.display_name).to match(/^n_plus_one_detection-error-courses#index-.+$/)
        expect(attachment.filename).to match(/^n_plus_one_detection-error-courses#index-.+\.txt$/)
        expect(attachment.content_type).to eql "text/plain"
        expect(attachment.root_account).to eql Account.site_admin
        expect(report_content).to start_with("<!DOCTYPE html>")
        expect(report_content).to include("<h1>Error Generating N Plus One Detection</h1>")
        expect(report_content).to include("<h2>Bad news bears (RuntimeError)</h2>")
      end
    end

    it "ensures Prosopite.finish is called even if an error occurs" do
      expect(Prosopite).to receive(:scan).and_call_original
      expect(Prosopite).to receive(:finish).and_call_original

      expect do
        service.call(user:, source_name:) { raise "Something went wrong!" }
      end.not_to raise_error
    end

    it "raises an error when not given a block" do
      expect do
        service.call(user:, source_name:)
      end.to raise_error(SiteAdminReportingService::NoBlockError, "Must provide a block!")
    end

    it "raises an error when user is not a site admin user" do
      expect do
        service.call(user: account_admin_user, source_name:) { "a block.." }
      end.to raise_error(SiteAdminReportingService::NonSiteAdminError, "Must be a siteadmin user!")
    end

    context "when block doesn't contain N+1 queries" do
      it "creates a report without N+1 detections" do
        service.call(user:, source_name:) do
          # Operation that should not trigger N+1 queries
          User.first
        end

        expect(attachment).to be_present
        expect(attachment.content_type).to eql "text/plain"
        expect(attachment.display_name).to match(/^n_plus_one_detection-courses#index-.+$/)
        content = attachment.open.read
        expect(content).to eql(NPlusOneDetection::NPlusOneDetectionService::HEADER_MESSAGE)
      end
    end

    context "when block contains N+1 queries" do
      before do
        course = course_factory
        student_in_course(course:)
        student_in_course(course:)
        student_in_course(course:)
      end

      it "creates a report when N+1 queries are potentially detected" do
        service.call(user:, source_name:, custom_name: "n1-test") do
          Course.all.each do |c| # rubocop:disable Rails/FindEach
            c.students.map do |s|
              s.pseudonyms.map(&:name)
            end
          end
        end

        aggregate_failures do
          expect(attachment).to be_present
          expect(attachment.display_name).to match(/^n_plus_one_detection-n1-test-courses#index-.+$/)
          expect(attachment.content_type).to eql "text/plain"
          expect(attachment.root_account).to eql Account.site_admin
          content = attachment.open.read
          # This is semi-brittle, as if Prosopite changes its output format, this will break,
          # but they likely won't change it, and the test will fail if they do.
          expect(content).to include("N+1 queries detected")
        end
      end
    end
  end
end
