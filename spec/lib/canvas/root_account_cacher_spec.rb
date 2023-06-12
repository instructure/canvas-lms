# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe Canvas::RootAccountCacher do
  specs_require_sharding

  it "does not get confused by the same account id on different shards" do
    user = User.create!
    user.pseudonyms.create!(unique_id: "p1", account: Account.default)
    a2 = nil
    @shard1.activate do
      a2 = Account.create!(id: Account.default.local_id)
      user.associate_with_shard(@shard1)
      a2.pseudonyms.create!(unique_id: "p2", user:)
    end
    RequestCache.enable do
      expect(user.reload.all_active_pseudonyms.map(&:account)).to eq [Account.default, a2]
    end
  end
end
