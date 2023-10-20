# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "report_spec_helper"

describe "Account Reports" do
  include ReportSpecHelper

  before :once do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @account = Account.create(name: "New Account", default_time_zone: "UTC")
    @admin = account_admin_user(account: @account)
    @course1 = Course.create(name: "English 101", course_code: "ENG101", account: @account)
  end

  describe "account report files" do
    it "has different filenames for each report even when md5 matches" do
      report1 = run_report("unpublished_courses_csv")
      report2 = run_report("unpublished_courses_csv")

      expect(report1.attachment.md5).to eq report2.attachment.md5
      expect(report1.attachment.filename).not_to eq report2.attachment.filename
    end
  end

  it "uses instfs if instfs is enabled" do
    allow(InstFS).to receive_messages(enabled?: true, direct_upload: "1234-abcd")

    report1 = run_report("unpublished_courses_csv")
    report2 = run_report("unpublished_courses_csv")

    expect(report1.attachment.md5).to eq report2.attachment.md5
    expect(report1.attachment.filename).not_to eq report2.attachment.filename
  end

  it "records the job id" do
    expect(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 1234))
    report = run_report("unpublished_courses_csv")
    expect(report.job_ids).to eq [1234]
  end

  it "records account report runner job ids for parallelized reports" do
    expect(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 123),
                                                                double("Delayed::Job", id: 456))
    report = run_report("grade_export_csv")
    expect(report.job_ids).to eq [123]
    expect(report.account_report_runners.first.job_ids).to eq [456]
  end

  it "retries PG::ConnectionBad" do
    retried = false
    AccountReports.configure_account_report "Default", {
      "fake_report" => {
        title: -> { "Fake Report" },
        proc: lambda do |report|
                unless retried
                  retried = true
                  raise PG::ConnectionBad
                end
                report.update workflow_state: "complete"
              end
      }
    }
    expect(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 123),
                                                                double("Delayed::Job", id: 456))

    ar = AccountReport.create!(account: Account.default, user: account_admin_user, report_type: "fake_report")
    ar.run_report
    run_jobs
    ar.reload
    expect(ar).to be_complete
    expect(ar.job_ids).to eq([123, 456])
  end

  it "does not retry PG::ConnectionBad forever" do
    count = 0
    AccountReports.configure_account_report "Default", {
      "sad_report" => {
        title: -> { "Sad Report" },
        proc: lambda do |_report|
                count += 1
                raise PG::ConnectionBad
              end
      }
    }
    ar = AccountReport.create!(account: Account.default, user: account_admin_user, report_type: "sad_report")
    ar.run_report
    run_jobs
    expect(count).to eq 3
    expect(ar.reload).to be_error
  end

  it "does not retry other exceptions" do
    count = 0
    AccountReports.configure_account_report "Default", {
      "sad_report" => {
        title: -> { "Sad Report" },
        proc: lambda do |_report|
                count += 1
                raise "fail"
              end
      }
    }
    ar = AccountReport.create!(account: Account.default, user: account_admin_user, report_type: "sad_report")
    ar.run_report
    run_jobs
    expect(count).to eq 1
    expect(ar.reload).to be_error
  end
end
