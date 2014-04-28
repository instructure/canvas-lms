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

class EventStream::Index
  include EventStream::AttrConfig

  attr_reader :event_stream

  attr_config :table, :type => String
  attr_config :id_column, :type => String, :default => 'id'
  attr_config :key_column, :type => String, :default => 'key'
  attr_config :bucket_size, :type => Fixnum, :default => 1.week
  attr_config :scrollback_limit, :type => Fixnum, :default => 52.weeks
  attr_config :entry_proc, :type => Proc
  attr_config :key_proc, :type => Proc, :default => nil

  def initialize(event_stream, &blk)
    @event_stream = event_stream
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def database
    event_stream.database
  end

  def bucket_for_time(time)
    time.to_i - (time.to_i % bucket_size)
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

  def for_key(key, options={})
    shard = EventStream.current_shard
    bookmarker = EventStream::Index::Bookmarker.new(self)
    BookmarkedCollection.build(bookmarker) do |pager|
      shard.activate { history(key, pager, options) }
    end
  end

  def create_key(bucket, key)
    [*key, bucket].join('/')
  end

  class Bookmarker
    def initialize(index)
      @index = index
    end

    def bookmark_for(item)
      if item.is_a?(@index.event_stream.record_type)
        @index.bookmark_for(item)
      else
        [item['bucket'], item['ordered_id']]
      end
    end

    def validate(bookmark)
      bookmark.is_a?(Array) && bookmark.size == 2
    end
  end

  def select_cql
    "SELECT ordered_id, #{id_column} FROM #{table} #{event_stream.read_consistency_clause}WHERE #{key_column} = ?"
  end

  def insert_cql
    "INSERT INTO #{table} (#{key_column}, ordered_id, #{id_column}) VALUES (?, ?, ?) USING TTL ?"
  end

  private

  def history(key, pager, options)
    # get the bucket to start at from the bookmark
    if pager.current_bookmark
      bucket, ordered_id = pager.current_bookmark
    elsif options[:newest]
      # page 1 with explicit start time
      bucket = bucket_for_time(options[:newest])
      ordered_id = "#{options[:newest].to_i + 1}/"
    else
      # page 1 implicit start at first event in "current" bucket
      bucket = bucket_for_time(Time.now)
      ordered_id = nil
    end

    # where to stop ("oldest" if given, defaulting to scrollback_limit, but
    # can't go past scrollback_limit)
    scrollback_limit = self.scrollback_limit.ago
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
      database.execute(qs, *args).fetch do |row|
        if pager.size == pager.per_page
          pager.has_more!
        else
          pager << row.to_hash.merge('bucket' => bucket)
        end
      end

      ordered_id = nil
      bucket -= bucket_size
    end

    # now that the bookmark's been set, convert the ids to rows from the
    # related event stream, preserving the order
    ids = pager.map { |row| row[id_column] }
    events = event_stream.fetch(ids)
    pager.replace events.sort_by { |event| ids.index(event.id) }
  end
end
