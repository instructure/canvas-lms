# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "Account Reports", type: :request do
  it "renders page with default reports and all custom_reports" do
    # If this test is failing from a change in a different report plugin, there
    # is possibly a mis-configured engine or misnamed view. If the debugger is
    # uncommented you can get a better error to work from, try looking at
    # ErrorReport.last.message or
    # puts  ErrorReport.last.backtrace;''
    account_admin_user account: Account.site_admin
    @admin = @user
    user_with_pseudonym(user: @admin,
                        username: "admin@example.com",
                        password: "password")
    user_session(@admin)
    @account = Account.default

    csv = Attachment.create!(filename: "grades_export.csv",
                             uploaded_data: StringIO.new("sometextgoeshere"),
                             context: @account)
    report = Account.default.account_reports.create!(user: @admin)
    report.workflow_state = "complete"
    report.progress = 100
    report.report_type = "student_assignment_outcome_map_csv"
    report.parameters = {}
    report.parameters["extra_text"] = "sometextgoeshere"
    report.attachment = csv
    report.save
    @account.save

    get "/accounts/#{@account.id}/reports_tab"
    expect(response).to be_successful
    expect(response.body).to match(/sometextgoeshere/)
  end
end
