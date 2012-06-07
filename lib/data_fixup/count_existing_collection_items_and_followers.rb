module DataFixup::CountExistingCollectionItemsAndFollowers
  def self.run
    Collection.active.find_ids_in_batches do |ids|
      Collection.connection.execute(Collection.send(:sanitize_sql_array, [<<-SQL, ids]))
        UPDATE collections c SET followers_count = (
          SELECT COUNT(*)
          FROM user_follows uf
          WHERE uf.followed_item_id = c.id
            AND uf.followed_item_type = 'Collection'
        ), items_count = (
          SELECT COUNT(*)
          FROM collection_items ci
          WHERE ci.workflow_state = 'active'
            AND ci.collection_id = c.id
        )
        WHERE id IN (?)
      SQL
    end
  end
end
