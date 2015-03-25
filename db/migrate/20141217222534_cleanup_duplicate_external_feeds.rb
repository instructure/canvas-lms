class CleanupDuplicateExternalFeeds < ActiveRecord::Migration
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
    remove_index :external_feeds, name: 'index_external_feeds_uniquely'
  end
end
