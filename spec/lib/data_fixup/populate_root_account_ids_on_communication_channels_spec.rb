# frozen_string_literal: true

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
  end

end
