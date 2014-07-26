module DataFixup
  class FixAuditLogUuidIndexes

    MAPPING_TABLE = 'corrupted_index_mapping'
    CORRUPTED_EVENT_TYPE = 'corrupted'
    INDEXES = [
      Auditors::Authentication::Stream.pseudonym_index,
      Auditors::Authentication::Stream.user_index,
      Auditors::Authentication::Stream.account_index,
      Auditors::Course::Stream.course_index,
      Auditors::GradeChange::Stream.assignment_index,
      Auditors::GradeChange::Stream.course_index,
      Auditors::GradeChange::Stream.root_account_grader_index,
      Auditors::GradeChange::Stream.root_account_student_index
    ]

    def self.run
      migration = new

      # Fix Indexes
      INDEXES.each do |index|
        migration.fix_index(index)
      end

      # Clean up
      migration.drop_mapping_table
    end

    def initialize
      @corrected_ids = {}

      return if mapping_table_exists?

      compression_params = database.db.use_cql3? ?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"

      cql = %{
        CREATE TABLE #{MAPPING_TABLE} (
          record_type           text,
          id                    text,
          new_id                text,
          created_at            timestamp,
          PRIMARY KEY (record_type, id, created_at)
        ) #{compression_params}
      }

      database.execute(cql)
    end

    # Check if the mapping table exits
    def mapping_table_exists?
      cql = %{
        SELECT columnfamily_name
        FROM System.schema_columnfamilies
        WHERE columnfamily_name = ?
          AND keyspace_name = ?
        ALLOW FILTERING
      }

      database.execute(cql, MAPPING_TABLE, database.keyspace).count == 1
    end

    # Drops mapping table
    def drop_mapping_table
      database.execute("DROP TABLE #{MAPPING_TABLE}") if mapping_table_exists?
    end

    # The date the bug was released.
    def start_time
      @start_time ||= Time.new(2014, 6, 14)
    end

    # Cassandra database connection
    def database
      @database ||= Canvas::Cassandra::DatabaseBuilder.from_config(:auditors)
    end

    # Fixes a specified index
    def fix_index(index)
      iterate_invalid_keys(index) do |rows|
        update_index_batch(index, rows)
      end
    end

    # Returns corrupted indexes.
    def iterate_invalid_keys(index)
      # page 1 implicit start at first event in "current" bucket
      bucket = index.bucket_for_time(Time.now)
      previous_bucket = bucket + index.bucket_size

      oldest_bucket = index.bucket_for_time(start_time)

      cql = %{
        SELECT #{index.id_column},
               #{index.key_column},
               ordered_id
        FROM #{index.table} %CONSISTENCY%
        WHERE ordered_id >= ?
          AND ordered_id < ?
        ALLOW FILTERING
      }

      # pull results from each bucket until the page is full or we go past the
      # end bucket
      until bucket < oldest_bucket
        array = []

        database.execute(cql, "#{bucket}/", "#{previous_bucket}/", consistency: index.event_stream.read_consistency_level).fetch do |row|
          row = row.to_hash
          # Strip the bucket off the key.
          row['index_key'] = row[index.key_column].split("/#{bucket}").first
          row['timestamp'] = row['ordered_id'].split('/').first.to_i
          array << row
        end

        yield array

        previous_bucket = bucket
        bucket -= index.bucket_size
      end
    end

    # Fixes a corrupted index record
    def update_index_batch(index, rows)
      need_inspection = []
      need_tombstone = []
      updates = []

      # Check each row to see if we need to update it or inspect it.
      rows.each do |row|
        current_id, timestamp, key = extract_row_keys(index, row)
        actual_id = query_corrected_id(index.event_stream, current_id, timestamp)
        if actual_id.nil?
          # We couldnt find a mapping so we need to fix this look into this one.
          need_inspection << row
        elsif actual_id != current_id
          # We have already created a base record for this index so this record just needs to be recreated.
          updates << [current_id, key, timestamp, actual_id]
        end
      end

      if need_inspection.present?
        ids = need_inspection.map{ |row| row[index.id_column] }
        events = index.event_stream.fetch(ids).index_by(&:id)
        need_inspection.each do |row|
          current_id, timestamp, key = extract_row_keys(index, row)
          event = events[current_id]

          # If the event is a corrupted event we have already fixed it so save
          # the mapping and move along.
          if event.event_type == 'corrupted'
            store_corrected_id(index.event_stream, current_id, timestamp, current_id)
            next
          end

          # If the timestamp is different we know its been changed.
          if event.created_at.to_i != timestamp
            need_tombstone << row
          elsif entry = index.entry_proc.call(event)
            # Get the index entry and key to match up the index's key to the records
            # key.  If they are different its corrupted.  If its the same we know its clean.
            # We need to convert the actual_key to a string, a proc might return a non string
            # but the index key will always be a string.
            actual_key = (index.key_proc ? index.key_proc.call(*entry) : entry).to_s
            if key != actual_key
              need_tombstone << row
            else
              store_corrected_id(index.event_stream, current_id, timestamp, current_id)
            end
          else
            # the current event data indicates no index entry should exist, but one
            # did, so the index entry must have referred to prior event data.
            need_tombstone << row
          end
        end
      end

      database.batch do
        if need_tombstone.present?
          # Loop through each record we need to create a tombstone for.
          need_tombstone.each do |row|
            current_id, timestamp, key = extract_row_keys(index, row)
            actual_id = CanvasUUID.generate
            create_tombstone(index.event_stream, actual_id, timestamp)
            store_corrected_id(index.event_stream, current_id, timestamp, actual_id)
            updates << [current_id, key, timestamp, actual_id]
          end
        end

        if updates.present?
          # Loop through each row that needs updating and delete the corrupted index
          # Then create a fixed tombstone index.
          updates.each do |current_id, key, timestamp, actual_id|
            delete_index_entry(index, current_id, key, timestamp)
            create_index_entry(index, actual_id, key, timestamp)
          end
        end
      end
    end

    # Extracts key information from a row
    def extract_row_keys(index, row)
      current_id = row[index.id_column]
      timestamp = row['timestamp']
      key = row['index_key']

      [current_id, timestamp, key]
    end

    # Returns the new_id if a mapping exists
    def query_corrected_id(stream, id, timestamp)
      key = corrected_id_key(stream, id, timestamp)
      if corrected_id = @corrected_ids[key]
        return corrected_id
      else
        database.execute("SELECT new_id FROM #{MAPPING_TABLE} WHERE record_type = ? AND id = ? AND created_at = ?", stream.record_type, id, timestamp).fetch do |row|
          return @corrected_ids[key] = row.to_hash['new_id']
        end
      end
    end

    # Stores a new_id in the mapping table
    def store_corrected_id(stream, current_id, timestamp, actual_id)
      database.execute("INSERT INTO #{MAPPING_TABLE} (record_type, id, new_id, created_at) VALUES (?, ?, ?, ?)", stream.record_type, current_id, actual_id, timestamp)
      @corrected_ids[corrected_id_key(stream, current_id, timestamp)] = actual_id
    end

    def corrected_id_key(stream, id, timestamp)
      [stream.record_type, id, timestamp].join('/')
    end

    def create_tombstone(stream, id, timestamp)
      ttl_seconds = stream.ttl_seconds(timestamp)
      return if ttl_seconds < 0

      database.insert_record(stream.table, {stream.id_column => id}, {
        'created_at' => Time.at(timestamp),
        'event_type' => CORRUPTED_EVENT_TYPE
      }, ttl_seconds)
    end

    # Creates an index for the record.
    def create_index_entry(index, id, key, timestamp)
      ttl_seconds = index.event_stream.ttl_seconds(timestamp)
      return if ttl_seconds < 0

      # Add the bucket back onto the key.
      key = index.create_key(index.bucket_for_time(timestamp), key)
      ordered_id = "#{timestamp}/#{id[0, 8]}"

      database.execute(index.insert_cql, key, ordered_id, id, ttl_seconds)
    end

    # Deletes a corrupted index entry.
    def delete_index_entry(index, id, key, timestamp)
      # Add the bucket back onto the key.
      key = index.create_key(index.bucket_for_time(timestamp), key)
      ordered_id = "#{timestamp}/#{id[0, 8]}"
      database.execute("DELETE FROM #{index.table} WHERE ordered_id = ? AND key = ?", ordered_id, key)
    end
  end
end
