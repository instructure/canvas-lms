#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdsOnCommunicationChannels do
  describe 'populate' do
    context 'when on the same shard as the user' do
      it 'copies the root_account_ids from the users table' do
        user_record = user_model
        ra_ids = [account_model.id, account_model.id]
        user_record.update_columns(root_account_ids: ra_ids)

        cc = CommunicationChannel.create!(user: user_record, path: 'canvas@instructure.com')
        cc.update_columns(root_account_ids: nil)

        expect {
          DataFixup::PopulateRootAccountIdOnModels.run
        }.to change { cc.reload.root_account_ids }.from(nil).to(ra_ids)
      end
    end

    context 'when on a different shard as the main user' do
      specs_require_sharding

      it 'copies the root_account_ids from the shadow user, correctly globalizing ids' do
        user0 = user_model
        user1 = @shard1.activate { user_model }
        account0 = account_model
        account1 = @shard1.activate { account_model }
        account2 = @shard2.activate { account_model }
        course0 = course_model(account: account0)
        course1 = @shard1.activate { course_model(account: account1) }
        course2 = @shard2.activate { course_model(account: account2) }

        # user on shard 0 belongs to shard0 account and shard2 account
        course0.enroll_user(user0, 'StudentEnrollment', enrollment_state: 'active')
        course2.enroll_user(user0, 'StudentEnrollment', enrollment_state: 'active')
        # user on shard 1 belongs to shard0 account, shard1 account and shard2 account
        course0.enroll_user(user1, 'StudentEnrollment', enrollment_state: 'active')
        course1.enroll_user(user1, 'StudentEnrollment', enrollment_state: 'active')
        course2.enroll_user(user1, 'StudentEnrollment', enrollment_state: 'active')

        @shard2.activate do
          cc0 = CommunicationChannel.create!(user: user0, path: 'canvas@instructure.com')
          cc1 = CommunicationChannel.create!(user: user1, path: 'canvas@instructure.com')

          [Shard.default, @shard1, @shard2].each do |shard|
            shard.activate do
              # CommunicationChannel backfill won't run until the users table
              # all has root_account_ids.  The backfill doesn't do that itself
              # because it won't copy over shadow users immediately in this
              # spec. So just update the root_account_ids to something bogus.
              # Fine for our purposes since we don't use it directly in
              # cross-shard CommunicationChannel fills
              User.update_all(root_account_ids: [Account.first.id])
            end
          end

          expect {
            DataFixup::PopulateRootAccountIdOnModels.run
          }.to change { [cc0, cc1].map{|cc| cc.reload.root_account_ids&.sort} }.from(
            [nil, nil]
          ).to([
            [account0.id, account2.id].sort,
            [account0.id, account1.id, account2.id].sort,
          ])
        end
      end
    end
  end

end
