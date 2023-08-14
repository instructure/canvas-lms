# frozen_string_literal: true

#
# Copyright (C) 2034 - present Instructure, Inc.
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

require_relative "../spec_helper"
require_relative "../../db/migrate/20230817180016_populate_view_admin_analytics_permission"

describe PopulateViewAdminAnalyticsPermission do
  subject { PopulateViewAdminAnalyticsPermission.new }

  it "creates role overrides for custom account roles with :view_analytics and :view_all_grades" do
    skip "analytics plugin required" unless RoleOverride.permissions.key?(:view_analytics)

    role1 = custom_account_role("Role1", account: Account.default)
    role1.role_overrides.create!(account: Account.default, permission: :view_analytics, enabled: true)
    role1.role_overrides.create!(account: Account.default, permission: :view_all_grades, enabled: true)

    role2 = custom_account_role("Role2", account: Account.default)
    role2.role_overrides.create!(account: Account.default, permission: :view_analytics, enabled: true)

    subject.up

    expect(role1.role_overrides.where(permission: :view_admin_analytics, enabled: true)).to exist
    expect(role2.role_overrides.where(permission: :view_admin_analytics)).not_to exist
  end
end
