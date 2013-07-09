#
# Copyright (C) 2013 Instructure, Inc.
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
  include AttrConfig

  attr_reader :event_stream

  attr_config :table, :type => String
  attr_config :id_column, :type => String, :default => 'id'
  attr_config :key_column, :type => String, :default => 'key'
  attr_config :bucket_size, :type => Fixnum, :default => 1.week
  attr_config :scrollback_setting, :type => String, :default => nil
  attr_config :scrollback_default, :type => Fixnum, :default => 52.weeks
  attr_config :entry_proc
  attr_config :key_proc, :default => nil

  def initialize(event_stream, &blk)
    @event_stream = event_stream
    instance_exec(&blk) if blk
    attr_config_validate
  end

  def database
    event_stream.database
  end

  def scrollback_limit
    if scrollback_setting
      Setting.get(scrollback_setting, scrollback_default.to_s).to_i
    else
      scrollback_default
    end
  end

  def bucket_for_time(time)
    time.to_i - (time.to_i % bucket_size)
  end

  def insert(id, key, timestamp)
    ttl_seconds = event_stream.ttl_seconds(timestamp)
    return if ttl_seconds < 0

    prefix = id.to_s[0,8]
    bucket = bucket_for_time(timestamp)
    key = "#{key}/#{bucket}"
    ordered_id = "#{timestamp.to_i}/#{prefix}"
    database.update(insert_cql, key, ordered_id, id, ttl_seconds)
  end

  def for_key(key)
    shard = Shard.current
    BookmarkedCollection.build(EventStream::Index::Bookmarker) do |pager|
      shard.activate { history(key, pager) }
    end
  end

  module Bookmarker
    def self.bookmark_for(item)
      [item['bucket'], item['ordered_id']]
    end

    def self.validate(bookmark)
      bookmark.is_a?(Array) && bookmark.size == 2
    end
  end

  private

  def insert_cql
    "INSERT INTO #{table} (#{key_column}, ordered_id, #{id_column}) VALUES (?, ?, ?) USING TTL ?"
  end

  def history(key, pager)
    # get the bucket to start at from the bookmark
    if pager.current_bookmark
      bucket, ordered_id = pager.current_bookmark
    else
      # page 1
      bucket = bucket_for_time(Time.now)
      ordered_id = nil
    end

    # pull results from each bucket until the page is full or we hit the
    # scrollback_limit
    scrollback_limit = self.scrollback_limit.ago
    until pager.next_bookmark || Time.at(bucket) < scrollback_limit
      # build up the query based on the context, bucket, and ordered_id. fetch
      # one extra so we can tell if there are more pages
      limit = pager.per_page + 1 - pager.size
      args = []
      args << "#{key}/#{bucket}"
      if ordered_id
        ordered_id_clause = (pager.include_bookmark ? "AND ordered_id <= ?" : "AND ordered_id < ?")
        args << ordered_id
      else
        ordered_id_clause = nil
      end
      qs = "SELECT ordered_id, #{id_column} FROM #{table} where #{key_column} = ? #{ordered_id_clause} ORDER BY ordered_id DESC LIMIT #{limit}"

      # execute the query collecting the results. set the bookmark iff there
      # was a result after the full page
      database.execute(qs, *args).fetch do |row|
        if pager.size == pager.per_page
          pager.has_more!
        else
          pager << row.to_hash.merge('bucket' => bucket)
        end
      end

      # possible optimization: query page_views_counters_by_context_and_day ,
      # and use it as a secondary index to skip days where the user didn't
      # have any page views
      ordered_id = nil
      bucket -= bucket_size
    end

    # now that the bookmark's been set, convert the ids to rows from the
    # related event stream, preserving the order
    ids = pager.map{ |row| row[id_column] }
    events = event_stream.fetch(ids)
    pager.replace events.sort_by{ |event| ids.index(event.id) }
  end
end
