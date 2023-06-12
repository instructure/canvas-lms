# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do
    # Account_Admin ID: 2 || Name: Admin1
    # Account ID: 2
    # Report ID: 1
    provider_state "a user with many account reports" do
      set_up do
        @account_admin = Pact::Canvas.base_state.account_admins.first
        @report = AccountReport.new
        @report.account = @account_admin.account
        @report.user = @account_admin
        @report.progress = rand(100)
        @report.start_at = Time.zone.now
        @report.end_at = (Time.zone.now + rand(60 * 60 * 4)).to_datetime
        @report.report_type = "student_assignment_outcome_map_csv"
        @report.parameters = ActiveSupport::HashWithIndifferentAccess["param" => "test", "error" => "failed"]
        folder = Folder.assert_path("test", @account_admin.account)
        @report.attachment = Attachment.create!(
          folder:, context: @account_admin.account, filename: "test.txt", uploaded_data: StringIO.new("test file")
        )
        @report.save!
      end
    end

    provider_state "a user with a robust account report" do
      set_up do
        @account_admin = Pact::Canvas.base_state.account_admins.first
        @account_user = AccountUser.create(account: @account, user: @user)
        @report = AccountReport.new
        @report.account = @account_admin.account
        @report.user = @account_admin
        @report.progress = rand(100)
        @report.start_at = Time.zone.now
        @report.end_at = (Time.zone.now + rand(60 * 60 * 4)).to_datetime
        @report.report_type = "student_assignment_outcome_map_csv"
        @report.parameters = ActiveSupport::HashWithIndifferentAccess["purple" => "test", "lovely" => "ears"]
        folder = Folder.assert_path("test", @account_admin.account)
        @report.attachment = Attachment.create!(folder:, context: @account_admin.account, filename: "test.txt", uploaded_data: StringIO.new("test file"))
        @report.save!
      end
    end
  end
end
