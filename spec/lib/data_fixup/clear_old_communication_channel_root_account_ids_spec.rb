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
#

require 'spec_helper'

describe DataFixup::ClearOldCommunicationChannelRootAccountIds do
  it "clears out root_account_ids" do
    a = account_model
    u1 = user_model
    u2 = user_model(root_account_ids: [a.id])
    u3 = user_model(root_account_ids: [a.id])
    CommunicationChannel.create!(user: u1, path: 'a@b.com')
    CommunicationChannel.create!(user: u2, path: 'a@b.com')
    CommunicationChannel.create!(user: u3, path: 'a@b.com')
    expect {
      described_class.run
    }.to change { CommunicationChannel.pluck(:root_account_ids).uniq }.from([nil, [a.id]]).to([nil])
  end
end
