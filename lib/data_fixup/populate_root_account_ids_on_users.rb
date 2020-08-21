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

module DataFixup::PopulateRootAccountIdsOnUsers
  # this method is called from PopulateRootAccountIdOnModels as an override
  # for :populate_root_account_ids
  def self.populate(min, max)
    # clamp to non-shadow users
    return if min >= Shard::IDS_PER_SHARD
    max = [max, Shard::IDS_PER_SHARD].min

    User.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      subquery = UserAccountAssociation.select("array_agg(DISTINCT root_account_id)").
        where("user_id=users.id").to_sql
      uniquify = "SELECT ARRAY(SELECT DISTINCT e FROM unnest(array_cat(root_account_ids, (#{subquery}))) AS a(e) ORDER BY e)"
      User.where(id: batch_min..batch_max).update_all("root_account_ids=(#{uniquify})")
    end
  end

  # Used in the standard model backfill to deterimine if the
  # `populate_table` method should be run
  def self.run_populate_table?
    User.where("id>?", Shard::IDS_PER_SHARD).any?
  end

  # This method will check for the presence of shadow users on
  # the current shard. If a shadow user exists, the method
  # will then update the corresponding primary user on
  # their primary shard with the root account from the
  # current shard. The result is that the primary user has
  # root_account_ids that look something like this:
  #
  # [1, 2, 20000000000001]
  #
  # The shadow user records, however, will not have their
  # root_account_ids column updated.
  def self.populate_table
    min = User.where("id>?", Shard::IDS_PER_SHARD).minimum(:id)
    source_shard = Shard.current

    # No cross-shard users were found
    return if min.nil?

    loop do
      # group into one other shard at a time
      foreign_shard = Shard.lookup(min / Shard::IDS_PER_SHARD)
      unless foreign_shard
        min = User.where("id>?", (min / Shard::IDS_PER_SHARD + 1) * Shard::IDS_PER_SHARD).minimum(:id)
        next if min
      end
      scope = UserAccountAssociation.where("user_id>=? AND user_id<?", min, (foreign_shard.id + 1) * Shard::IDS_PER_SHARD)
      scope.find_ids_in_batches do |batch|
        root_accounts = UserAccountAssociation.connection.select_rows(
          UserAccountAssociation.where(id: batch).
            select("user_id, array_agg(DISTINCT root_account_id)").
            group(:user_id).to_sql)
        # yes, this could probably done in a single query with a VALUES table, but this should be a relatively
        # small case and I don't want to figure out the JOIN with the UPDATE
        root_accounts.each do |(user_id, root_accounts_for_user)|
          root_accounts_for_user = root_accounts_for_user[1..-1].split(',').map(&:to_i)
          translated_ids = root_accounts_for_user.map {|id| Shard.relative_id_for(id, source_shard, foreign_shard)}

          uniquify = "SELECT ARRAY(SELECT DISTINCT e FROM unnest(array_cat(root_account_ids, ('{#{translated_ids.join(',')}}'))) AS a(e) ORDER BY e)"

          User.where(id: user_id).update_all("root_account_ids=(#{uniquify})")
        end
      end
      min = User.where("id>?", (foreign_shard.id + 1) * Shard::IDS_PER_SHARD).minimum(:id)
      break if min.nil?
    end
  end
end
