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
    provider_state 'a user with many account reports' do
      set_up do
        @admin = account_admin_user

        Pseudonym.create!(user:@admin, unique_id: 'testadminaccount@instructure.com')
        token = @admin.access_tokens.create!().full_token

        @report = AccountReport.new
        @report.account = @admin.account
        @report.user = @admin
        @report.progress=rand(100)
        @report.start_at=Time.zone.now
        @report.end_at=(Time.zone.now + rand(60*60*4)).to_datetime
        @report.report_type = "student_assignment_outcome_map_csv"
        @report.parameters = HashWithIndifferentAccess['param' => 'test', 'error'=>'failed']
        folder = Folder.assert_path("test", @admin.account)
        @report.attachment = Attachment.create!(
          :folder => folder, :context => @admin.account, :filename => "test.txt", :uploaded_data => StringIO.new("test file")
        )
        @report.save!

        provider_param :token, token
        provider_param :account_id, @admin.account.id.to_s
        provider_param :report_type, @report.report_type.to_s
        provider_param :report_id, @report.id.to_s
      end
    end

    provider_state 'a user with a robust account report' do
      set_up do
        @user = user_factory(:active_all => true)
        @account = account_model
        @account_user = AccountUser.create(:account => @account, :user => @user)

        Pseudonym.create!(user:@user, unique_id: 'testaccountuser@instructure.com')
        token = @user.access_tokens.create!().full_token

        @report = AccountReport.new
        @report.account = @account
        @report.user = @user
        @report.progress=rand(100)
        @report.start_at=Time.zone.now
        @report.end_at=(Time.zone.now + rand(60*60*4)).to_datetime
        @report.report_type = "student_assignment_outcome_map_csv"
        @report.parameters = HashWithIndifferentAccess['purple' => 'test', 'lovely'=>'ears']

        folder = Folder.assert_path("test", @account)
        @report.attachment = Attachment.create!(:folder => folder, :context => @account, :filename => "test.txt", :uploaded_data => StringIO.new("test file"))

        @report.save!

        provider_param :token, token
        provider_param :account_id, @account.id.to_s
        provider_param :report_type, @report.report_type.to_s
        provider_param :report_id, @report.id.to_s
      end
    end
  end
end