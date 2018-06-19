#
# Copyright (C) 2018 - present Instructure, Inc.
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

module PermissionsHelper
  def manageable_enrollments_by_permission(permission)
    raise "invalid permission" unless RoleOverride.permissions.keys.include?(permission.to_sym)

    enrollments = cached_current_enrollments(preload_courses: true)
    allowed_ens = []
    Shard.partition_by_shard(enrollments) do |sharded_enrollments|
      perms_hash = get_permission_info_by_account(sharded_enrollments, permission)
      allowed_ens += sharded_enrollments.select do |e|
        perm_hash = perms_hash[e.course.account_id]
        perm_hash && enabled_for_enrollment(e.role_id, e.type, perm_hash, permission)
      end
    end
    allowed_ens
  end

  def enabled_for_enrollment(role_id, role_type, perm_hash, permission)
    true_for_roles = RoleOverride.permissions[permission.to_sym][:true_for]
    # enabled by account role
    return true if perm_hash[:admin_roles].any? do |role|
      role_on = perm_hash.dig(:role_overrides, role.id, :enabled) && perm_hash.dig(:role_overrides, role.id, :self)
      role_on.nil? ? true_for_roles.include?(role.base_role_type) : role_on
    end
    # enabled for enrollment role
    role_on = perm_hash.dig(:role_overrides, role_id, :enabled) && perm_hash.dig(:role_overrides, role_id, :self)
    role_on.nil? ? true_for_roles.include?(role_type) : role_on
  end

  # examines permissions for accounts related to enrollments and returns a map from account_id to a hash containing
  #  sub_accounts: set of subaccount ids
  #  role_overrides: map from role id to hash containing :enabled, :locked, :self, :children
  #   (these are calculated for the specific account, taking inheritance and locking into account)
  #  admin_roles: set of Roles the user has active account memberships for in this account
  def get_permission_info_by_account(enrollments, permission)
    account_roles = AccountUser.where(user: self).active.preload(:role)
    role_ids = (enrollments.map(&:role_id) + account_roles.map(&:role_id)).uniq
    root_account_ids = enrollments.map(&:root_account_id).uniq
    query = <<-SQL
      WITH RECURSIVE t(id, name, parent_account_id, role_id, enabled, locked, self, children) AS (
        SELECT accounts.id, name, parent_account_id, ro.role_id, ro.enabled, ro.locked,
          ro.applies_to_self, ro.applies_to_descendants
        FROM #{Account.quoted_table_name}
        LEFT JOIN #{RoleOverride.quoted_table_name} AS ro ON ro.context_id = accounts.id
                                                         AND ro.context_type = 'Account'
                                                         AND ro.permission = :permission
                                                         AND ro.role_id IN (:role_ids)
        WHERE accounts.id IN (:account_ids)
      UNION
        SELECT accounts.id, accounts.name, accounts.parent_account_id, ro.role_id, ro.enabled,
          ro.locked, ro.applies_to_self, ro.applies_to_descendants
        FROM #{Account.quoted_table_name}
        INNER JOIN t ON accounts.id = t.parent_account_id
        LEFT JOIN #{RoleOverride.quoted_table_name} AS ro ON ro.context_id = accounts.id
                                                         AND ro.context_type = 'Account'
                                                         AND ro.permission = :permission
                                                         AND ro.role_id IN (:role_ids)
        WHERE accounts.workflow_state = 'active'
      )
      SELECT *
      FROM t
      SQL
    params = {
      account_ids: enrollments.map { |e| e.course.account_id },
      permission: permission,
      role_ids: role_ids
    }
    rows = User.connection.execute(sanitize_sql([query, params]))
    hash_permissions(rows, root_account_ids, account_roles)
  end

  private

  def hash_permissions(rows, root_account_ids, account_roles)
    perms_hash = {}
    new_perm = {sub_accounts: Set.new, role_overrides: {}, admin_roles: Set.new}
    root_account_ids.each{|ri| perms_hash[ri] = new_perm.deep_dup}
    rows.each do |row|
      account_id = row['id']
      parent_id = row['parent_account_id']
      role_id = row['role_id']
      override = {enabled: row['enabled'], locked: row['locked'], self: row['self'], children: row['children']}
      perms_hash[account_id] ||= new_perm.deep_dup
      perms_hash[account_id][:role_overrides][role_id] = override if role_id
      perms_hash[account_id][:admin_roles] += account_roles.select{|au| au.account_id == account_id}.map(&:role)
      if parent_id
        perms_hash[parent_id] ||= new_perm.deep_dup
        perms_hash[parent_id][:sub_accounts] << row['id']
      end
    end
    root_account_ids.each do |rai|
      fill_permissions_recursive(perms_hash, rai, perms_hash[rai])
    end
    perms_hash
  end

  def fill_permissions_recursive(perms_hash, id, parent_hash)
    perm_hash = perms_hash[id]
    unless parent_hash == perm_hash
      parent_hash[:role_overrides].each_pair do |ro, parent_values|
        next if parent_values[:children] == false && !parent_values[:locked]
        perm_hash[:role_overrides][ro] = parent_values.slice(:locked, :enabled, :children) if perm_hash[:role_overrides][ro].nil? || parent_values[:locked]
        perm_hash[:role_overrides][ro][:self] = parent_values[:children] if perm_hash[:role_overrides][ro][:self].nil?
      end
      perm_hash[:admin_roles] += parent_hash[:admin_roles]
    end
    perm_hash[:sub_accounts].each{|sa| fill_permissions_recursive(perms_hash, sa, perm_hash)}
  end

end
