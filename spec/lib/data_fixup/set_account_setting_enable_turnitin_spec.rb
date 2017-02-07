#
# Copyright (C) 2016 Instructure, Inc.
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

describe DataFixup::SetAccountSettingEnableTurnitin do
  let(:account) do
    Account.create!(name: 'turnitin tester', turnitin_account_id: '1234',
      turnitin_shared_secret: '1234')
  end

  it "adds enable_turnitin to accounts that have a non-null account_id and crypted_secret" do
    account
    DataFixup::SetAccountSettingEnableTurnitin.run

    account.reload
    expect(account).to be_enable_turnitin
  end

  it "doesn't add turnitin to accounts that have a null crypted_secret" do
    account.update!(turnitin_crypted_secret: nil)
    DataFixup::SetAccountSettingEnableTurnitin.run

    account.reload
    expect(account).to_not be_enable_turnitin
  end

  it "doesn't add turnitin to accounts that have a null account_id" do
    account.update!(turnitin_account_id: nil)
    DataFixup::SetAccountSettingEnableTurnitin.run

    account.reload
    expect(account).to_not be_enable_turnitin
  end
end
