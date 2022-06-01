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

describe AccountReportRunner do
  describe "start" do
    let(:account) { account_model }
    let(:admin) { user_model }

    it "removes any existing account report rows that pre-exist the run" do
      account.enable_feature!(:custom_report_experimental)
      report = AccountReport.create!(account_id: account.id, user_id: admin.id)
      arr = AccountReportRunner.create!(created_at: 1.day.ago, account_report_id: report.id)
      a_row = AccountReportRow.create!(account_report_id: report.id, account_report_runner_id: arr.id, created_at: 1.day.ago)
      expect(AccountReportRunner.where(id: arr.id).count).to eq(1)
      expect(AccountReportRow.where(id: a_row.id).count).to eq(1)
      arr.start
      arr.abort
      expect(AccountReportRow.where(id: a_row.id).count).to eq(0)
    end

    it "does not remove any existing account report rows that pre-exist the run if feature flag not enabled" do
      report = AccountReport.create!(account_id: account.id, user_id: admin.id)
      arr = AccountReportRunner.create!(created_at: 1.day.ago, account_report_id: report.id)
      a_row = AccountReportRow.create!(account_report_id: report.id, account_report_runner_id: arr.id, created_at: 1.day.ago)
      expect(AccountReportRunner.where(id: arr.id).count).to eq(1)
      expect(AccountReportRow.where(id: a_row.id).count).to eq(1)
      arr.start
      arr.abort
      expect(AccountReportRow.where(id: a_row.id).count).to eq(1)
    end
  end
end
