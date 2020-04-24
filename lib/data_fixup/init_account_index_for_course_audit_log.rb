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
#

module DataFixup
  class InitAccountIndexForCourseAuditLog

    LAST_BATCH_TABLE = 'courses_index_last_batch'.freeze

    def self.run
      fixup = new
      fixup.create_batch_table
      fixup.process_records
    end

    def create_batch_table
      Rails.logger.debug("InitAccountIndexForCourseAuditLog: #{LAST_BATCH_TABLE} exists? => #{table_exists?(LAST_BATCH_TABLE)}")
      unless table_exists?(LAST_BATCH_TABLE)
        compression_params = if database.db.use_cql3?
          "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }"
        else
          "WITH compression_parameters:sstable_compression='DeflateCompressor'"
        end

        create_table_command = %{
        CREATE TABLE #{LAST_BATCH_TABLE} (
          id int,
          last_id text,
          PRIMARY KEY (id)
        ) #{compression_params}
        }
        database.execute(create_table_command)
      end
    end

    def drop_table
      database.execute %{DROP TABLE #{LAST_BATCH_TABLE};}
    end

    SEARCH_CQL = %{
      SELECT id, created_at, course_id, account_id
      FROM courses
      WHERE token(id) > token(?)
      LIMIT ?
    }.freeze

    UPDATE_CQL = %{
      UPDATE courses SET account_id = ? WHERE id = ?
    }.freeze

    ResultStruct = Struct.new(:index, :record, :key)

    def read_batch_size
      @read_batch_size ||=
        Setting.get('init_account_index_for_course_audit_log_read_batch_size', 1000).to_i
    end

    def write_batch_size
      @write_batch_size ||=
        Setting.get('init_account_index_for_course_audit_log_write_batch_size', 200).to_i
    end

    def database
      @database ||= Canvas::Cassandra::DatabaseBuilder.from_config(:auditors)
    end

    def process_records
      last_seen_id = fetch_last_id
      loop do
        result = database.execute(SEARCH_CQL, last_seen_id, read_batch_size)
        break if result.rows == 0

        log_message("Read #{result.rows} records from courses table")

        # save rows locally so we can loop through multiple times
        rows = []
        result.fetch do |row|
          rows << row
        end

        # build course_id to account_id lookup map to speed things up
        course_ids = rows.map { |r| r['course_id'] }.uniq
        account_course_map = Hash[ Course.where(:id => course_ids).pluck(:id, :account_id).map { |e| [Shard.global_id_for(e[0]), Shard.global_id_for(e[1])] } ]

        batch_updates = []
        batch_inserts = []
        last_id = nil

        rows.each do |row|
          if row['account_id'].nil?
            # lookup account from course id, can also cache here
            account_id = account_course_map[ row['course_id'] ]
            # update course row with account id
            batch_updates << [ account_id, row['id'] ]
            # write account id to index
            batch_inserts << add_course_account_index(row, account_id)
          end
          last_id = row['id']
        end

        log_message("Writing #{batch_updates.count} updates to courses table")
        write_updates_in_batches(batch_updates)

        log_message("Writing #{batch_inserts.count} inserts to courses_by_account index table")
        write_inserts_in_batches(batch_inserts)

        save_last_id(last_id)
        last_seen_id = last_id

        log_message("Batch Complete")
      end
    end

    def write_updates_in_batches(updates)
      while updates.size > 0
        write_batch_updates(updates.shift(write_batch_size))
      end
    end

    def write_batch_updates(updates)
      return if updates.empty?
      database.batch { updates.each { |upd| database.execute(UPDATE_CQL, *upd) } }
    end

    def write_inserts_in_batches(inserts)
      while inserts.size > 0
        write_batch_inserts(inserts.shift(write_batch_size))
      end
    end

    def write_batch_inserts(inserts)
      return if inserts.empty?
      database.batch { inserts.each { |r| r.index.insert(r.record, r.key) } }
    end

    def add_course_account_index(row, account_id)
      index = ::Auditors::Course::Stream.account_index
      key = [account_id]
      ResultStruct.new(index, OpenStruct.new(row.to_hash), key)
    end

    def fetch_last_id
      database.execute("SELECT last_id FROM #{LAST_BATCH_TABLE}").fetch do |row|
        return row.to_hash['last_id']
      end
      nil
    end

    def save_last_id(last_id)
      database.execute("INSERT INTO #{LAST_BATCH_TABLE} (id, last_id) VALUES (1, ?) ", last_id)
    end

    def log_message(message)
      Rails.logger.debug("InitAccountIndexForCourseAuditLog: #{message}")
    end

    def table_exists?(table)
      cql = %{
        SELECT *
        FROM #{table}
        LIMIT 1
      }
      database.execute(cql)
      true
    rescue CassandraCQL::Error::InvalidRequestException
      false
    end
  end
end
