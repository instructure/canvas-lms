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
    # Notification IDs: 1, 2, 3.
    provider_state "a user with many notifications" do
      set_up do
        account_admin = Pact::Canvas.base_state.account_admins.first
        account = account_admin.account
        @notification1 = AccountNotification.create!(
          account:, subject: "test subj1", message: "test msg", start_at: Time.zone.now, end_at: 3.days.from_now, user: account_admin
        )
        @notification2 = AccountNotification.create!(
          account:, subject: "test subj2", message: "test msg", start_at: Time.zone.now, end_at: 3.days.from_now, user: account_admin
        )
        @notification3 = AccountNotification.create!(
          account:, subject: "test subj3", message: "test msg", start_at: Time.zone.now, end_at: 3.days.from_now, user: account_admin
        )
      end
    end
  end
end
