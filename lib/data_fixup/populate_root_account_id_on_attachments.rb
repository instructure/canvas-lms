# frozen_string_literal: true

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

module DataFixup::PopulateRootAccountIdOnAttachments

  # This is a little different than the other PopulateRootAccountId fix ups.
  # Since Attachments needs multiple passes, in order, they all happen here.
  # DataFixup::PopulateRootAccountIdOnModels triggers this fixup
  # as part of the `populate_overrides` call. Hopefully no comedy ensues.
  def self.populate(min, max)

    # First pass: do standard migration
    # Not inside of Attachment.find_ids_in_ranges since that is called inside of
    # PopulateRootAccountIdOnModels
    from_model(min, max)

    Attachment.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      # Second pass: try namespace
      from_namespace(batch_min, batch_max)

      # Third pass: set any stragglers to root_account_id: 0
      default_to_zero(batch_min, batch_max)
    end
  end

  def self.from_model(min, max)
    DataFixup::PopulateRootAccountIdOnModels.tap do |fixup|
      association_hash = fixup.hash_association(fixup.dependencies[Attachment])
      direct_relation_associations = fixup.replace_polymorphic_associations(Attachment, association_hash)
      fixup.populate_root_account_ids(Attachment, direct_relation_associations, min, max)
    end
  end

  def self.from_namespace(batch_min, batch_max)
    attachments = Attachment.
        where(id: batch_min..batch_max, root_account_id: nil).
        where('namespace is not null') # ignore the poor, orphaned attachments (deleted?)

    return if attachments.empty? # no droids here, move along

    id_to_global = attachments.
      select(:id, :namespace).
      pluck(:id, :namespace).
      map do |attachment_id, namespace|
        # Attachment#namespace is a mix bag of local (1, account_1) and gobal
        # (account_20000000000001) account ids, convert to local and back to
        # global to ensure everything is a global id in the end.
        namespace_id = namespace.split('_').last
        local_account_id, shard_id = Shard.local_id_for(namespace_id)
        global_account_id = Shard.global_id_for(local_account_id, shard_id)

        [attachment_id, global_account_id]
      end

    # join in the mappings by treating it as a values table:
    #   VALUES ('id', 'global'), ..
    # This allows for one update for everything instead of per record
    id_mapping_list = Arel::Nodes::ValuesList.new(id_to_global)

    # Joining with `update_at`, the values table causes a
    # `PostgreSQL update_all/delete_all only supports INNER JOIN` error,
    # so have to manually craft the SQL.
    query = %{
      UPDATE #{Attachment.quoted_table_name}
      SET root_account_id = id_mapping.global_account_id
      FROM (#{id_mapping_list.to_sql})
        AS id_mapping (attachment_id, global_account_id)
      WHERE "attachments"."id" = "id_mapping"."attachment_id"
    }.squish

    ActiveRecord::Base.connection.execute(query)
  end

  def self.default_to_zero(batch_min, batch_max)
    Attachment.
        where(id: batch_min..batch_max, root_account_id: nil).
        update_all(root_account_id: 0)
  end
end