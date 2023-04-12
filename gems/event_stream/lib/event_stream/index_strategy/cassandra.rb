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
#
require "active_support/core_ext/module/delegation"

module EventStream::IndexStrategy
  class Cassandra
    attr_reader :index

    def initialize(index_obj)
      @index = index_obj
    end

    delegate :event_stream, to: :index
    delegate :database, to: :event_stream

    def bucket_for_time(time)
      time.to_i - (time.to_i % index.bucket_size)
    end

    def bookmark_for(record)
      prefix = record.id.to_s[0, 8]
      bucket = bucket_for_time(record.created_at)
      ordered_id = "#{record.created_at.to_i}/#{prefix}"
      [bucket, ordered_id]
    end

    def insert(record, key)
      ttl_seconds = event_stream.ttl_seconds(record.created_at)
      return if ttl_seconds < 0

      bucket, ordered_id = bookmark_for(record)
      key = create_key(bucket, key)
      database.update(insert_cql, key, ordered_id, record.id, ttl_seconds)
    end

    def create_key(bucket, key)
      [*key, bucket].join("/")
    end

    def select_cql
      "SELECT ordered_id, #{index.id_column}, #{index.key_column} FROM #{index.table} %CONSISTENCY% WHERE #{index.key_column} = ?"
    end

    def insert_cql
      "INSERT INTO #{index.table} (#{index.key_column}, ordered_id, #{index.id_column}) VALUES (?, ?, ?) USING TTL ?"
    end

    def find_with(args, options)
      key = index.key_proc ? index.key_proc.call(*args) : args
      for_key(key, options)
    end

    def find_ids_with(args, options)
      key = index.key_proc ? index.key_proc.call(*args) : args
      ids_for_key(key, options)
    end

    def for_key(key, options = {})
      shard = EventStream.current_shard
      bookmarker = EventStream::IndexStrategy::Cassandra::Bookmarker.new(self)
      BookmarkedCollection.build(bookmarker) do |pager|
        shard.activate { history(key, pager, options) }
      end
    end

    # does the exact same scan as "for_key",
    # but returns  just the IDs rather than
    # random-accessing the datastore for the attributes
    # for each id.  Mostly for use in bulk-scan
    # operations like transferring all data from
    # one store to another.
    def ids_for_key(key, options = {})
      shard = EventStream.current_shard
      bookmarker = EventStream::IndexStrategy::Cassandra::Bookmarker.new(self)
      BookmarkedCollection.build(bookmarker) do |pager|
        shard.activate { ids_only_history(key, pager, options) }
      end
    end

    class Bookmarker
      def initialize(cass_index)
        @cass_index = cass_index
      end

      def bookmark_for(item)
        if item.is_a?(@cass_index.event_stream.record_type)
          @cass_index.bookmark_for(item)
        else
          [item["bucket"], item["ordered_id"]]
        end
      end

      def validate(bookmark)
        bookmark.is_a?(Array) && bookmark.size == 2
      end
    end

    def ids_only_history(key, pager, options)
      # get the bucket to start at from the bookmark
      if pager.current_bookmark
        bucket, ordered_id = pager.current_bookmark
      elsif options[:newest]
        # page 1 with explicit start time
        bucket = bucket_for_time(options[:newest])
        ordered_id = "#{options[:newest].to_i + 1}/"
      else
        # page 1 implicit start at first event in "current" bucket
        bucket = bucket_for_time(Time.zone.now)
        ordered_id = nil
      end
      # where to stop ("oldest" if given, defaulting to scrollback_limit, but
      # can't go past scrollback_limit)
      scrollback_limit = index.scrollback_limit.seconds.ago
      oldest = options[:oldest] || scrollback_limit
      oldest = scrollback_limit if oldest < scrollback_limit
      oldest_bucket = bucket_for_time(oldest)
      lower_bound = "#{oldest.to_i}/"
      if ordered_id && (pager.include_bookmark ? ordered_id < lower_bound : ordered_id <= lower_bound)
        # no possible results
        pager.replace []
        return pager
      end
      # pull results from each bucket until the page is full or we go past the
      # end bucket
      until pager.next_bookmark || bucket < oldest_bucket
        # build up the query based on the context, bucket, and ordered_id. fetch
        # one extra so we can tell if there are more pages
        limit = pager.per_page + 1 - pager.size
        args = []
        args << create_key(bucket, key)
        args << lower_bound
        if ordered_id
          ordered_id_clause = (pager.include_bookmark ? "AND ordered_id <= ?" : "AND ordered_id < ?")
          args << ordered_id
        else
          ordered_id_clause = nil
        end
        qs = "#{select_cql} AND ordered_id >= ? #{ordered_id_clause} ORDER BY ordered_id DESC LIMIT #{limit}"
        # execute the query collecting the results. set the bookmark iff there
        # was a result after the full page
        database.execute(qs, *args, consistency: event_stream.read_consistency_level).fetch do |row|
          if pager.size == pager.per_page
            pager.has_more!
          else
            pager << row.to_hash.merge("bucket" => bucket)
          end
        end
        ordered_id = nil
        bucket -= index.bucket_size
      end
      pager
    end

    def history(key, pager, options)
      pager = ids_only_history(key, pager, options)
      ids = pager.pluck(index.id_column)
      fetch_strategy = options.fetch(:fetch_strategy, :batch)
      events = event_stream.fetch(ids, strategy: fetch_strategy)
      pager.replace(events.sort_by { |event| ids.index(event.id) })
    end
  end
end
