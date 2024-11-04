# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
describe DataFixup::EnableChildSettingsForPronunciation do
  before(:once) do
    @account = Account.create!(root_account_id: nil)
  end

  it "enables granular settings when parent setting is enabled" do
    @account.settings[:enable_name_pronunciation] = true
    @account.settings[:allow_name_pronunciation_edit_for_admins] = false
    @account.save!

    DataFixup::EnableChildSettingsForPronunciation.run
    updated_setting = @account.reload.settings[:allow_name_pronunciation_edit_for_admins]
    expect(updated_setting).to be_truthy
  end

  it "does nothing when parent setting is false" do
    @account.settings[:enable_name_pronunciation] = false
    @account.settings[:allow_name_pronunciation_edit_for_admins] = false
    @account.save!

    DataFixup::EnableChildSettingsForPronunciation.run
    updated_setting = @account.reload.settings[:allow_name_pronunciation_edit_for_admins]
    expect(updated_setting).to be_falsy
  end
end
