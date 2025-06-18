# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
describe DataFixup::Lti::DeleteInvalidManageLtiRegistrationsRoleOverrides do
  subject { DataFixup::Lti::DeleteInvalidManageLtiRegistrationsRoleOverrides.run }

  it "only deletes the correct role overrides and ignores all others" do
    root_account = Account.default
    sub_account = account_model(parent_account: Account.default)

    sub_account_role = custom_account_role("sub", account: sub_account)
    root_override = RoleOverride.create!(context: root_account,
                                         permission: "manage_developer_keys",
                                         role: custom_account_role("root", account: root_account),
                                         enabled: true)
    sub_account_override = RoleOverride.create!(context: sub_account,
                                                permission: "manage_developer_keys",
                                                role: sub_account_role,
                                                enabled: true)
    invalid_override = RoleOverride.create!(context: sub_account,
                                            permission: "manage_lti_registrations",
                                            role: sub_account_role,
                                            enabled: true)

    expect { subject }.to change { RoleOverride.count }.by(-1)

    expect(RoleOverride.exists?(invalid_override.id)).to be false
    expect(RoleOverride.exists?(sub_account_override.id)).to be true
    expect(RoleOverride.exists?(root_override.id)).to be true
  end
end
