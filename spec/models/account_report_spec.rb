# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe AccountReport do
  describe ".delete_old_rows_and_runners" do
    let(:account) { account_model }
    let(:admin) { user_model }

    it "cleans up old db records" do
      report = AccountReport.create!(account_id: account.id, user_id: admin.id)
      arr = AccountReportRunner.create!(created_at: 60.days.ago, account_report_id: report.id)
      a_row = AccountReportRow.create!(account_report_id: report.id, account_report_runner_id: arr.id, created_at: 60.days.ago)
      AccountReport.delete_old_rows_and_runners
      expect(AccountReportRunner.where(id: arr.id).count).to eq(0)
      expect(AccountReportRow.where(id: a_row.id).count).to eq(0)
    end

    it "manages the edge of the delete window" do
      report = AccountReport.create!(account_id: account.id, user_id: admin.id)
      arr = AccountReportRunner.create!(created_at: 31.days.ago, account_report_id: report.id)
      a_row = AccountReportRow.create!(account_report_id: report.id, account_report_runner_id: arr.id, created_at: 26.days.ago)
      a_row_2 = AccountReportRow.create!(account_report_id: report.id, account_report_runner_id: arr.id, created_at: 31.days.ago)
      AccountReport.delete_old_rows_and_runners
      expect(AccountReportRunner.where(id: arr.id).count).to eq(1)
      expect(AccountReportRow.where(id: a_row.id).count).to eq(1)
      expect(AccountReportRow.where(id: a_row_2.id).count).to eq(0)
    end
  end

  describe "stopping parallelized reports" do
    before :once do
      @account = account_model
      @report = AccountReport.create!(account: @account, user: account_admin_user, workflow_state: "running")
      @runners = [@report.account_report_runners.create!(workflow_state: "completed"),
                  @report.account_report_runners.create!(workflow_state: "running"),
                  @report.account_report_runners.create!(workflow_state: "created")]
    end

    it "aborts runners when errored" do
      @report.mark_as_errored
      expect(@runners.map { |r| r.reload.workflow_state }).to eq %w[completed aborted aborted]
    end

    it "aborts runners when deleted" do
      @report.destroy
      expect(@runners.map { |r| r.reload.workflow_state }).to eq %w[completed aborted aborted]
    end

    it "aborts runners when aborted" do
      @report.update! workflow_state: "aborted"
      expect(@runners.map { |r| r.reload.workflow_state }).to eq %w[completed aborted aborted]
    end

    it "leaves runners alone when completed" do
      @report.update! workflow_state: "completed"
      expect(@runners.map { |r| r.reload.workflow_state }).to eq %w[completed running created]
    end
  end
end
