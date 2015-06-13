module DataFixup::PopulateStreamItemAssociations
  def self.run
    while true
      batch = StreamItem.connection.select_all(<<-SQL)
        SELECT id, context_type, context_id, context_code, asset_type, asset_id, item_asset_string
        FROM stream_items
        WHERE (context_type IS NULL AND context_code IS NOT NULL) OR
              (asset_type IS NULL AND item_asset_string IS NOT NULL)
        LIMIT 1000
SQL
      break if batch.empty?
      batch.each do |si|
        updates = {}
        if si['context_code'].present? && (!si['context_type'].present? || !si['context_id'].present?)
          context_type, context_id = ActiveRecord::Base.parse_asset_string(si['context_code'])
          updates[:context_type] = context_type
          updates[:context_id] = context_id
        end
        if si['item_asset_string'].present? && (!si['asset_type'].present? || !si['asset_id'].present?)
          asset_type, asset_id = ActiveRecord::Base.parse_asset_string(si['item_asset_string'])
          updates[:asset_type] = asset_type
          updates[:asset_id] = asset_id
        end
        begin
          StreamItem.update_all(updates, :id => si['id']) unless updates.empty?
        rescue ActiveRecord::RecordNotUnique
          # duplicate!
          # we have no way of knowing which one (or both) has stream item instances,
          # so just let the first one win
          StreamItem.where(:id => si['id']).delete_all
        end
      end
    end

    while true
      batch = StreamItemInstance.connection.select_all(<<-SQL)
        SELECT id, context_type, context_id, context_code
        FROM stream_items
        WHERE context_type IS NULL AND context_code IS NOT NULL
        LIMIT 1000
SQL
      break if batch.empty?
      batch.each do |sii|
        updates = {}
        context_type, context_id = ActiveRecord::Base.parse_asset_string(sii['context_code'])
        updates[:context_type] = context_type
        updates[:context_id] = context_id
        StreamItemInstance.where(:id => sii['id']).update_all(updates)
      end
    end
  end
end
