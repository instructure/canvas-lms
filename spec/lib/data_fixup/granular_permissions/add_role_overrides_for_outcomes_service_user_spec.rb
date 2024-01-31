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

describe "DataFixup::GranularPermissions::AddRoleOverridesToOutcomesServiceUser" do
  before(:once) do
    @account = account_model(parent_account: Account.site_admin)
    @outcome_siteadmin_user = custom_account_role("Outcomes Service", account: Account.site_admin)
    @outcome_sub_user = custom_account_role("Outcomes Service", account: @account)
    existing_perms = %w[
      read_global_outcomes
      read_outcomes
      read_course_content
      read_course_list
    ]
    existing_perms.each do |perm|
      @outcome_siteadmin_user.role_overrides.create!(permission: perm, context: Account.site_admin)
      @outcome_sub_user.role_overrides.create!(permission: perm, account: @account) unless perm == "read_course_list"
    end
    @needed_permissions = %w[
      manage_rubrics
      view_all_grades
    ]
  end

  it "adds missing permissions to outcomes service users" do
    expect(@outcome_siteadmin_user.role_overrides.count).to eq 4
    expect(@outcome_sub_user.role_overrides.count).to eq 3

    DataFixup::GranularPermissions::AddRoleOverridesToOutcomesServiceUser.run

    expect(@outcome_siteadmin_user.role_overrides.pluck(:permission)).to include(*@needed_permissions)
    expect(@outcome_sub_user.role_overrides.pluck(:permission)).to include(*@needed_permissions)
    expect(@outcome_sub_user.role_overrides.pluck(:permission)).to include("read_course_list")
  end

  it "ignores non-outcome service users" do
    @siteadmin_user = custom_account_role("API Service", account: Account.site_admin)
    @sub_user = custom_account_role("API Service", account: @account)

    expect(@siteadmin_user.role_overrides.count).to eq 0
    expect(@sub_user.role_overrides.count).to eq 0

    DataFixup::GranularPermissions::AddRoleOverridesToOutcomesServiceUser.run
    expect(@siteadmin_user.role_overrides.pluck(:permission)).to be_empty
    expect(@sub_user.role_overrides.pluck(:permission)).to be_empty
  end
end
