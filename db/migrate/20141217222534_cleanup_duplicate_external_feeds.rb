#
# Copyright (C) 2014 - present Instructure, Inc.
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

class CleanupDuplicateExternalFeeds < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    uniq_fields = %w(context_id context_type url header_match verbosity)
    scope = ExternalFeed.group(uniq_fields).select(uniq_fields).having("COUNT(*) > 1")
    scope.find_each do |baddie|
      duplicate_scope = ExternalFeed.where(baddie.attributes.slice(*uniq_fields))
      keeper = duplicate_scope.order(:id).first.id
      duplicate_scope.where('id != ?', keeper).find_ids_in_batches do |id_batch|
        DiscussionTopic.where(external_feed_id: id_batch).update_all(external_feed_id: keeper)
        ExternalFeedEntry.where(external_feed_id: id_batch).delete_all
        ExternalFeed.where(id: id_batch).delete_all
      end
    end

    ExternalFeed.find_ids_in_ranges do |start_id, end_id|
      ExternalFeed.where(id: start_id..end_id).where(verbosity: nil).
        update_all(verbosity: 'full')
    end

    uniq_fields_without_header = uniq_fields - %w(header_match)
    add_index :external_feeds, uniq_fields_without_header, unique: true, algorithm: :concurrently, where: "header_match IS NULL", name: 'index_external_feeds_uniquely_1'
    add_index :external_feeds, uniq_fields, unique: true, algorithm: :concurrently, where: "header_match IS NOT NULL", name: 'index_external_feeds_uniquely_2'
  end

  def down
    remove_index :external_feeds, name: 'index_external_feeds_uniquely_1'
    remove_index :external_feeds, name: 'index_external_feeds_uniquely_2'
  end
end
