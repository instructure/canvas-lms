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

module DataFixup::CopyBuiltInRolesByRootAccount
  def self.run
    root_account_ids = Account.root_accounts.non_shadow.pluck(:id).sort
    if root_account_ids.count == 1
      # easy-mode: just update the old built in roles to the one root account
      Role.where(:workflow_state => "built_in", :root_account_id => nil).update_all(:root_account_id => root_account_ids.first)
    else
      # otherwise make a copy for all the root accounts
      existing_root_ids = Role.where(:workflow_state => "built_in").where.not(:root_account_id => nil).distinct.pluck(:root_account_id)
      root_account_ids -= existing_root_ids # some root accounts might have already had their own copies made if they were created postdeploy
      return unless root_account_ids.any?

      new_role_data = root_account_ids.flat_map{|id| Role::BASE_TYPES.map{|type| {
        :name => type, :base_role_type => type, :root_account_id => id, :workflow_state => "built_in", :created_at => Time.now.utc, :updated_at => Time.now.utc
      }}}
      Role.bulk_insert(new_role_data)

      # and datafixup references to the old built in roles
      old_role_ids = Role.where(:workflow_state => "built_in", :root_account_id => nil).pluck(:id)

      [AccountUser, RoleOverride].each do |klass|
        klass.find_ids_in_ranges do |min_id, max_id|
          klass.where(:id => min_id..max_id, :role_id => old_role_ids).joins(:role).
            joins(<<~JOIN_SQL).update_all("role_id=new_roles.id")
              INNER JOIN #{Role.quoted_table_name} AS new_roles
              ON new_roles.base_role_type=roles.base_role_type
              AND new_roles.workflow_state='built_in'
              AND new_roles.root_account_id=#{klass.table_name}.root_account_id
            JOIN_SQL
        end
      end

      AccountNotificationRole.find_ids_in_ranges do |min_id, max_id|
        AccountNotificationRole.where(:id => min_id..max_id, :role_id => old_role_ids).joins(:role).
          joins(:account_notification => :account).joins(<<~JOIN_SQL).update_all("role_id=new_roles.id")
            INNER JOIN #{Role.quoted_table_name} AS new_roles
            ON new_roles.base_role_type=roles.base_role_type
            AND new_roles.workflow_state='built_in'
            AND new_roles.root_account_id=COALESCE(accounts.root_account_id, accounts.id)
          JOIN_SQL
      end

      Enrollment.find_ids_in_ranges(:batch_size => 100_000) do |start_at, end_at|
        # these are taking long enough that we should batch them
        self.send_later_if_production_enqueue_args(
          :move_roles_for_enrollments,
          {
            priority: Delayed::LOW_PRIORITY,
            n_strand: ["built_in_roles_copy_fixup_for_enrollments", Shard.current.database_server.id]
          },
          old_role_ids, start_at, end_at
        )
      end
    end
  end

  def self.move_roles_for_enrollments(old_role_ids, start_at, end_at)
    Enrollment.find_ids_in_ranges(start_at: start_at, end_at: end_at) do |min_id, max_id|
      Enrollment.where(:id => min_id..max_id, :role_id => old_role_ids).joins(:role).
        joins(<<~JOIN_SQL).update_all("role_id=new_roles.id")
              INNER JOIN #{Role.quoted_table_name} AS new_roles
              ON new_roles.base_role_type=roles.base_role_type
              AND new_roles.workflow_state='built_in'
              AND new_roles.root_account_id=enrollments.root_account_id
      JOIN_SQL
    end
  end
end
