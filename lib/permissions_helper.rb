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
    permission = permission.to_sym
    raise "invalid permission" unless RoleOverride.permissions.keys.include?(permission)

    enrollments = cached_current_enrollments(preload_courses: true, preload_dates: true)
    allowed_ens = []
    Shard.partition_by_shard(enrollments) do |sharded_enrollments|
      perms_hash = get_permissions_info_by_account(sharded_enrollments.map(&:course), sharded_enrollments, [permission])
      allowed_ens += sharded_enrollments.select do |e|
        perm_hash = perms_hash[e.course.account_id]
        perm_hash && (enabled_for_account_admin(perm_hash, permission) ||
          enabled_for_enrollment(e.role_id, e.type, e.state_based_on_date, perm_hash, permission))
      end
    end
    allowed_ens
  end

  # will return a hash linking global course ids with precalculated permissions
  # e.g. {10000000000001 => {:manage_calendar => true, :manage_assignments => false}}
  def precalculate_permissions_for_courses(courses, permissions, loaded_root_accounts=[])
    courses = courses.reject(&:deleted?) # just in case
    permissions = permissions.map(&:to_sym)
    nonexistent_permissions = permissions - RoleOverride.permissions.keys
    raise "invalid permissions - #{nonexistent_permissions}" if nonexistent_permissions.any?

    precalculated_map = {}
    Shard.partition_by_shard(courses, lambda(&:shard)) do |sharded_courses|
      unpublished, published = sharded_courses.partition(&:unpublished?)
      all_applicable_enrollments = []
      enrollment_scope = Enrollment.not_inactive_by_date.for_user(self).select("enrollments.*, enrollment_states.state AS date_based_state_in_db")
      all_applicable_enrollments += enrollment_scope.where(:course_id => unpublished).
        where(:type => ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'StudentViewEnrollment']).to_a if unpublished.any?
      all_applicable_enrollments += enrollment_scope.where(:course_id => published).to_a if published.any?

      grouped_enrollments = all_applicable_enrollments.group_by(&:course_id)
      sharded_courses.each do |course|
        grouped_enrollments[course.id] ||= []
        grouped_enrollments[course.id].each{|e| e.course = course}
      end

      root_account_ids = sharded_courses.map(&:root_account_id).uniq
      unloaded_ra_ids = root_account_ids - loaded_root_accounts.map(&:id)
      root_accounts = loaded_root_accounts + (unloaded_ra_ids.any? ? Account.where(:id => unloaded_ra_ids).to_a : [])

      roles = root_accounts.map{|ra| self.roles(ra)}.flatten.uniq
      return nil if roles.include?('consortium_admin') # cross-shard precalculation doesn't work - just fallback to the usual calculations
      is_account_admin = roles.include?('admin')
      account_roles = is_account_admin ? AccountUser.where(user: self).active.preload(:role).to_a : []
      all_permissions_data = get_permissions_info_by_account(sharded_courses, all_applicable_enrollments, permissions, account_roles)

      sharded_courses.each do |course|
        course_permissions = {}
        permissions.each do |permission|
          perm_hash = all_permissions_data[course.account_id]
          course_permissions[permission] = !!(perm_hash &&
            (enabled_for_account_admin(perm_hash, permission) || grouped_enrollments[course.id].any?{|e|
                enabled_for_enrollment(e.role_id, e.type, e.date_based_state_in_db.to_sym, perm_hash, permission)}))
        end

        # load some other permissions that we can possibly skip calculating - we can't say for sure they're false but we can mark them true
        active_ens = grouped_enrollments[course.id].select{|e| e.date_based_state_in_db.to_sym == :active}
        course_permissions[:read] = true if active_ens.any?
        if active_ens.any?(&:student?)
          course_permissions[:read_grades] = true
          course_permissions[:participate_as_student] = true
        end
        if grouped_enrollments[course.id].any?(&:admin?)
          course_permissions[:read] = true
          course_permissions[:read_as_admin] = true
        elsif !is_account_admin
          course_permissions[:read_as_admin] = false # wait a second i can totally mark this one as false if they don't have any account users
        end
        precalculated_map[course.global_id] = course_permissions
      end
    end
    precalculated_map
  end

  def enabled_for_account_admin(perm_hash, permission)
    # enabled by account role
    permission_details = RoleOverride.permissions[permission]
    true_for_roles = permission_details[:true_for]
    available_to_roles = permission_details[:available_to]

    perm_hash[:admin_roles].any? do |role|
      if available_to_roles.include?(role.base_role_type)
        role_on = perm_hash.dig(:role_overrides, [role.id, permission], :enabled) && perm_hash.dig(:role_overrides, [role.id, permission], :self)
        role_on.nil? ? true_for_roles.include?(role.base_role_type) : role_on
      end
    end
  end

  def enabled_for_enrollment(role_id, role_type, enrollment_state, perm_hash, permission)
    role_type = "StudentEnrollment" if role_type == "StudentViewEnrollment"
    permission_details = RoleOverride.permissions[permission]
    true_for_roles = permission_details[:true_for]
    available_to_roles = permission_details[:available_to]

    # enabled for enrollment role
    if enrollment_state == :completed
      concluded_roles = permission_details[:applies_to_concluded]
      return false unless concluded_roles
      return false if concluded_roles.is_a?(Array) && !concluded_roles.include?(role_type)
    elsif enrollment_state != :active # future
      return false if permission_details[:restrict_future_enrollments]
    end

    if available_to_roles.include?(role_type)
      role_on = perm_hash.dig(:role_overrides, [role_id, permission], :enabled) && perm_hash.dig(:role_overrides, [role_id, permission], :self)
      role_on.nil? ? true_for_roles.include?(role_type) : role_on
    else
      false
    end
  end

  # examines permissions for accounts related to enrollments and returns a map from account_id to a hash containing
  #  sub_accounts: set of subaccount ids
  #  role_overrides: map from role id to hash containing :enabled, :locked, :self, :children
  #   (these are calculated for the specific account, taking inheritance and locking into account)
  #  admin_roles: set of Roles the user has active account memberships for in this account
  def get_permissions_info_by_account(courses, enrollments, permissions, account_roles=nil)
    account_roles ||= AccountUser.where(user: self).active.preload(:role).to_a
    role_ids = (enrollments.map(&:role_id) + account_roles.map(&:role_id)).uniq
    root_account_ids = courses.map(&:root_account_id).uniq
    query = <<-SQL
      WITH RECURSIVE t(id, name, parent_account_id, role_id, enabled, locked, self, children, permission) AS (
        SELECT accounts.id, name, parent_account_id, ro.role_id, ro.enabled, ro.locked,
          ro.applies_to_self, ro.applies_to_descendants, ro.permission
        FROM #{Account.quoted_table_name}
        LEFT JOIN #{RoleOverride.quoted_table_name} AS ro ON ro.context_id = accounts.id
                                                         AND ro.context_type = 'Account'
                                                         AND ro.permission IN (:permissions)
                                                         AND ro.role_id IN (:role_ids)
        WHERE accounts.id IN (:account_ids)
      UNION
        SELECT accounts.id, accounts.name, accounts.parent_account_id, ro.role_id, ro.enabled,
          ro.locked, ro.applies_to_self, ro.applies_to_descendants, ro.permission
        FROM #{Account.quoted_table_name}
        INNER JOIN t ON accounts.id = t.parent_account_id
        LEFT JOIN #{RoleOverride.quoted_table_name} AS ro ON ro.context_id = accounts.id
                                                         AND ro.context_type = 'Account'
                                                         AND ro.permission IN (:permissions)
                                                         AND ro.role_id IN (:role_ids)
        WHERE accounts.workflow_state = 'active'
      )
      SELECT *
      FROM t
      SQL
    params = {
      account_ids: courses.map(&:account_id),
      permissions: permissions,
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
      permission = row['permission']
      perms_hash[account_id] ||= new_perm.deep_dup
      if role_id && permission
        override = {enabled: row['enabled'], locked: row['locked'], self: row['self'], children: row['children']}
        perms_hash[account_id][:role_overrides][[role_id, permission.to_sym]] = override
      end
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
