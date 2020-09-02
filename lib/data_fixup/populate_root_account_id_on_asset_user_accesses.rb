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

module DataFixup::PopulateRootAccountIdOnAssetUserAccesses
  def self.populate(min, max)
    # all other context types are handled in PopulateRootAccountIdOnModels
    to_transform = AssetUserAccess.where(id: min..max, context_type: "User")

    asset_types = %w(attachment calendar_event group course)

    # find any other asset types besides these and "user" (which the backfill fills with 0)
    types_string = [*asset_types, "user"].map{ |t| "'%#{t}%'" }.join(',')
    other_asset_types = to_transform.where("asset_code NOT LIKE ALL (ARRAY[#{types_string}])").
      distinct.
      pluck(Arel.sql("regexp_matches(asset_user_accesses.asset_code, '(\\w+)_\\d+') AS asset_type")).
      flatten

    unless other_asset_types.empty?
      Canvas::Errors.capture('new asset_user_accesses asset types', {
        shard_id: Shard.current.id,
        asset_types: other_asset_types
      })
    end

    asset_types.each do |type|
      qtn = type.classify.constantize.quoted_table_name
      to_transform.where("asset_code like ?", "%#{type}%").
        joins("INNER JOIN #{qtn} ON #{qtn}.id = cast(reverse(split_part(reverse(asset_user_accesses.asset_code), '_', 1)) as bigint)").
        in_batches.
        update_all("root_account_id=#{qtn}.root_account_id")
    end

    # Context=user and asset=User records are unfillable. Fill with 0 (dummy root account ID)
    to_transform.where("asset_code like ?", "%user\\_%").where(root_account_id: nil).update_all("root_account_id=0")
  end
end
