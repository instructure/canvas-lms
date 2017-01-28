#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe "Account Reports" , type: :request do

  it "should see extra text when there is extra text" do

    account_admin_user :account => Account.site_admin
    @admin = @user
    user_with_pseudonym :user => @admin, :username => 'admin@example.com', :password => 'password'
    user_session(@admin)
    @account = Account.default

    csv = Attachment.create!(:filename => 'grades_export.csv', :uploaded_data => StringIO.new('sometextstuffgoeshere'), :context => @account)
    report = Account.default.account_reports.create!(user: @admin)
    report.workflow_state = "complete"
    report.progress = 100
    report.report_type = "student_assignment_outcome_map_csv"
    report.parameters = {}
    report.parameters["extra_text"] = 'someuniquetextstuffgoeshere'
    report.attachment = csv
    report.save
    @account.save

    get "/accounts/#{@account.id}/settings"
    expect(response).to be_success
    expect(response.body).to match /someuniquetextstuffgoeshere/
  end
end
