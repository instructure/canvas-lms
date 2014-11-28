#
# Copyright (C) 2014 Instructure, Inc.
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
#

module DataFixup
  module FixAuditLogUuidIndexes
    MAPPING_TABLE = 'corrupted_index_mapping'
    LAST_BATCH_TABLE = 'index_last_batch'
    CORRUPTED_EVENT_TYPE = 'corrupted'

    class Migration
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
      end

      def batch_size
        @batch_size ||= Setting.get('fix_audit_log_uuid_indexes_batch_size', 1000).to_i
      end

      def get_last_batch(index)
        database.execute("SELECT key, ordered_id, batch_number FROM #{LAST_BATCH_TABLE} WHERE index_table = ?", index.table).fetch do |row|
          row = row.to_hash
          return [ row['key'], row['ordered_id'], row['batch_number'] ]
        end

        return ['', '', 0]
      end

      def save_last_batch(index, key, ordered_id, batch_number)
        database.execute("INSERT INTO #{LAST_BATCH_TABLE} (index_table, key, ordered_id, batch_number) VALUES (?, ?, ?, ?)", index.table, key, ordered_id, batch_number)
      end

      # Cassandra database connection
      def database
        @database ||= Canvas::Cassandra::DatabaseBuilder.from_config(:auditors)
      end

      def log_message(message)
        Rails.logger.debug("FixAuditLogUuidIndexes: #{message}.")
      end

      # Fixes a specified index
      def fix_index(index)
        index_cleaner = IndexCleaner.new(index)
        start_key, start_ordered_id, batch_number = get_last_batch(index)
        iterate_invalid_keys(index, start_key, start_ordered_id) do |rows, last_seen_key, last_seen_ordered_id|
          index_cleaner.clean(rows)
          batch_number += 1
          save_last_batch(index, last_seen_key, last_seen_ordered_id, batch_number)
          log_message "Finished batch #{batch_number} (#{rows.size} rows) for index table: #{index.table} at key: #{last_seen_key}, #{last_seen_ordered_id}"
        end
      end

      # Returns corrupted indexes.
      def iterate_invalid_keys(index, last_seen_key = '', last_seen_ordered_id = '')

        cql = %{
        SELECT #{index.id_column},
               #{index.key_column},
               ordered_id
        FROM #{index.table} %CONSISTENCY%
        WHERE token(#{index.key_column}) > token(?)
        LIMIT ?
        }

        loop do
          if last_seen_ordered_id == ''
            rows = []
            database.execute(cql, last_seen_key, batch_size, consistency: index.event_stream.read_consistency_level).fetch do |row|
              row = row.to_hash
              last_seen_key = row[index.key_column]
              last_seen_ordered_id = row['ordered_id']
              rows << row
            end
            break if rows.empty?
            yield rows, last_seen_key, last_seen_ordered_id
          end

          # Sort of lame but we need to get the rest of the rows if the limit exculded them.
          get_ordered_id_rows(index, last_seen_key, last_seen_ordered_id) do |rows, last_seen_ordered_id|
            yield rows, last_seen_key, last_seen_ordered_id
          end

          last_seen_ordered_id = ''
        end
      end

      def get_ordered_id_rows(index, last_seen_key, last_seen_ordered_id)
        return if last_seen_key.blank?

        cql = %{
        SELECT #{index.id_column},
               #{index.key_column},
               ordered_id
        FROM #{index.table} %CONSISTENCY%
        WHERE #{index.key_column} = ?
          AND ordered_id > ?
        LIMIT ?
        }

        loop do
          rows = []

          database.execute(cql, last_seen_key, last_seen_ordered_id, batch_size, consistency: index.event_stream.read_consistency_level).fetch do |row|
            row = row.to_hash
            last_seen_ordered_id = row['ordered_id']
            rows << row
          end

          break if rows.empty?
          yield rows, last_seen_ordered_id
        end
      end
    end

    class IndexCleaner
      def self.clean_index_records(index, rows)
        cleaner = new(index)

        # Clean the records
        updated_indexes = cleaner.clean(rows)

        # Get Updated Ids
        rows.map do |row|
          row_id = row[index.id_column]

          # Look to see if this row was fixed.  If so return that id.
          updated_indexes[cleaner.updated_index_key(row_id, row['timestamp'])] || row_id
        end
      end

      def initialize(index)
        @index = index
        @corrected_ids = {}
      end

      # The date the bug was released.
      def start_time
        @start_time ||= Time.new(2014, 6, 14)
      end

      def index
        @index
      end

      def stream
        @index.event_stream
      end

      def database
        @index.database
      end

      # Returns the new_id if a mapping exists
      def query_corrected_id(id, timestamp)
        key = corrected_id_key(id, timestamp)
        if corrected_id = @corrected_ids[key]
          return corrected_id
        else
          database.execute("SELECT new_id FROM #{MAPPING_TABLE} WHERE record_type = ? AND id = ? AND created_at = ?", stream.record_type, id, timestamp).fetch do |row|
            return @corrected_ids[key] = row.to_hash['new_id']
          end
        end
      end

      # Stores a new_id in the mapping table
      def store_corrected_id(current_id, timestamp, actual_id)
        database.execute("INSERT INTO #{MAPPING_TABLE} (record_type, id, new_id, created_at) VALUES (?, ?, ?, ?)", stream.record_type, current_id, actual_id, timestamp)
        @corrected_ids[corrected_id_key(current_id, timestamp)] = actual_id
      end

      def corrected_id_key(id, timestamp)
        [stream.record_type, id, timestamp].join('/')
      end

      # Extracts key information from a row
      def extract_row_keys(index, row)
        current_id = row[index.id_column]
        timestamp = row['timestamp']
        key = row['index_key']

        [current_id, timestamp, key]
      end

      def format_row(row)
        # Strip the bucket off the key.
        keys = row[index.key_column].split('/')
        row['bucket'] = keys.pop.to_i
        row['index_key'] = keys.join('/')
        row['timestamp'] = row['ordered_id'].split('/').first.to_i

        row
      end

      # cleans corrupted index rows
      def clean(rows)
        updated_indexes = {}
        need_inspection = []
        need_tombstone = []
        updates = []
        oldest_bucket = index.bucket_for_time(start_time)

        # Check each row to see if we need to update it or inspect it.
        rows.each do |row|
          row = format_row(row)
          next if row['bucket'] < oldest_bucket
          current_id, timestamp, key = extract_row_keys(index, row)
          actual_id = query_corrected_id(current_id, timestamp)
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

            # An index record might exist without a related event.
            # Just skip this for now.
            next unless event

            # If the event is a corrupted event we have already fixed it so save
            # the mapping and move along.
            if event.event_type == CORRUPTED_EVENT_TYPE
              store_corrected_id(current_id, timestamp, current_id)
              next
            end

            # If the timestamp is different we know its been changed.
            if event.created_at.to_i != timestamp
              need_tombstone << row
            else
              # Some entries might not have a valid key anymore so we need to catch that.
              begin
                entry = index.entry_proc.call(event)
              rescue ActiveRecord::RecordNotFound
                next
              end

              if entry
                # Get the index entry and key to match up the index's key to the records
                # key.  If they are different its corrupted.  If its the same we know its clean.
                # We need to convert the actual_key to a string, a proc might return a non string
                # but the index key will always be a string.
                actual_key = (index.key_proc ? index.key_proc.call(*entry) : entry)
                actual_key = actual_key.is_a?(Array) ? actual_key.join('/') : actual_key.to_s
                if key != actual_key
                  need_tombstone << row
                else
                  store_corrected_id(current_id, timestamp, current_id)
                end
              else
                # the current event data indicates no index entry should exist, but one
                # did, so the index entry must have referred to prior event data.
                need_tombstone << row
              end
            end
          end
        end

        database.batch do
          if need_tombstone.present?
            # Loop through each record we need to create a tombstone for.
            need_tombstone.each do |row|
              current_id, timestamp, key = extract_row_keys(index, row)
              actual_id = CanvasUUID.generate
              create_tombstone(actual_id, timestamp)
              store_corrected_id(current_id, timestamp, actual_id)
              updates << [current_id, key, timestamp, actual_id]
            end
          end

          if updates.present?
            # Loop through each row that needs updating and delete the corrupted index
            # Then create a fixed tombstone index.
            updates.each do |current_id, key, timestamp, actual_id|
              delete_index_entry(current_id, key, timestamp)
              create_index_entry(actual_id, key, timestamp)
              updated_indexes[updated_index_key(current_id, timestamp)] = actual_id
            end
          end
        end

        updated_indexes
      end

      def updated_index_key(id, timestamp)
        "#{id}/#{timestamp}"
      end

      def create_tombstone(id, timestamp)
        ttl_seconds = stream.ttl_seconds(timestamp)
        return if ttl_seconds < 0

        database.insert_record(stream.table, {stream.id_column => id}, {
          'created_at' => Time.at(timestamp),
          'event_type' => CORRUPTED_EVENT_TYPE
        }, ttl_seconds)
      end

      # Creates an index for the record.
      def create_index_entry(id, key, timestamp)
        ttl_seconds = stream.ttl_seconds(timestamp)
        return if ttl_seconds < 0

        # Add the bucket back onto the key.
        key = index.create_key(index.bucket_for_time(timestamp), key)
        ordered_id = "#{timestamp}/#{id[0, 8]}"

        database.execute(index.insert_cql, key, ordered_id, id, ttl_seconds)
      end

      # Deletes a corrupted index entry.
      def delete_index_entry(id, key, timestamp)
        # Add the bucket back onto the key.
        key = index.create_key(index.bucket_for_time(timestamp), key)
        ordered_id = "#{timestamp}/#{id[0, 8]}"
        database.execute("DELETE FROM #{index.table} WHERE ordered_id = ? AND #{index.key_column} = ?", ordered_id, key)
      end
    end
  end
end
