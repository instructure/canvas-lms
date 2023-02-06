# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::PopulateRootAccountIdsForCommunicationChannels do
  let(:account) { account_model }

  describe(".run") do
    it "updates the root_account_ids when nil" do
      user = User.create
      user.update_column(:root_account_ids, [account.id])
      cc = CommunicationChannel.create(user: user, path: "user@example.com")
      cc.update_column(:root_account_ids, nil)

      expect(cc.root_account_ids).to be_nil

      expect do
        DataFixup::PopulateRootAccountIdsForCommunicationChannels.run
      end.to change { cc.reload.root_account_ids }.from(nil).to(user.root_account_ids)
    end

    it "updates the root_account_ids when []" do
      user = User.create
      user.update_column(:root_account_ids, [account.id])
      cc = CommunicationChannel.create(user: user, path: "user@example.com")
      cc.update_column(:root_account_ids, [])

      expect(cc.root_account_ids).to eq []

      expect do
        DataFixup::PopulateRootAccountIdsForCommunicationChannels.run
      end.to change { cc.reload.root_account_ids }.from([]).to(user.root_account_ids)
    end
  end
end
