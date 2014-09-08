# Initialize CavasEventStream gem

Rails.configuration.to_prepare do
  EventStream.current_shard_lookup = -> { Shard.current }

  EventStream.get_index_ids_lookup = lambda { |index, rows|
    if DataFixup::FixAuditLogUuidIndexes::Migration::INDEXES.include?(index)
      DataFixup::FixAuditLogUuidIndexes::IndexCleaner.clean_index_records(index, rows)
    else
      rows.map { |row| row[index.id_column] }
    end
  }
end
