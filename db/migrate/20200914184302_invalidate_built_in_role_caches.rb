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

class InvalidateBuiltInRoleCaches < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    if Account.root_accounts.non_shadow.count > 1 && Role.where(:workflow_state => "built_in", :root_account_id => nil).exists?
      # otherwise we didn't bother changing role ids so there's nothing that needs to be cleared
      [[AccountUser, :account_users], [Enrollment, :enrollments]].each do |klass, cache_type|
        klass.find_ids_in_ranges(batch_size: 500_000) do |start_at, end_at|
          DataFixup::InvalidateBuiltInRoleCaches.
            delay_if_production(priority: Delayed::LOWER_PRIORITY,
              n_strand: ["built_in_roles_cache_clearing", Shard.current.database_server.id]).
            run(klass, cache_type, start_at, end_at)
        end
      end
    end

    if Shard.current.default?
      # will clear cached role overrides everywhere
      Account.site_admin&.
        delay_if_production(priority: Delayed::LOWER_PRIORITY,
          singleton: "clear_downstream_role_caches:#{Account.site_admin&.global_id}").
        clear_downstream_caches(:role_overrides)
    end
  end

  def down
  end
end
