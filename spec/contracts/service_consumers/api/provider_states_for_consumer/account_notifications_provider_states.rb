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
    provider_state 'a user with many notifications' do
      set_up do
        @user = user_factory(:active_all => true)
        @account = account_model
        @account_user = AccountUser.create(:account => @account, :user => @user)

        Pseudonym.create!(user:@user, unique_id: 'testaccountuser@instructure.com')
        token = @user.access_tokens.create!().full_token

        @notification1 = AccountNotification.create!(
          account: @account, subject: 'test subj1', message: 'test msg', start_at: Time.zone.now, end_at: 3.days.from_now
        )
        @notification2 = AccountNotification.create!(
          account: @account, subject: 'test subj2', message: 'test msg', start_at: Time.zone.now, end_at: 3.days.from_now
        )
        @notification3 = AccountNotification.create!(
          account: @account, subject: 'test subj3', message: 'test msg', start_at: Time.zone.now, end_at: 3.days.from_now
        )

        provider_param :token, token
        provider_param :account_id, @account.id.to_s
        provider_param :notification1_id, @notification1.id.to_s
        provider_param :notification2_id, @notification2.id.to_s
        provider_param :notification3_id, @notification3.id.to_s
      end
    end
  end
end