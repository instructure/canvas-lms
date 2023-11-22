# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe DataFixup::BackfillSoftDeletedUserRootAccountIds do
  it "calculates root account ids for a user with a deleted pseudonym" do
    user = User.create!
    p = user.pseudonyms.create!(unique_id: "user@domain.com", account: Account.default)
    p.destroy

    described_class.run

    user.reload
    expect(user.root_account_ids).to eq [Account.default.id]
  end
end
