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
module EventStream::IndexStrategy
  class ActiveRecord
    attr_reader :index

    def initialize(index_obj)
      @index = index_obj
    end

    def find_with(args, options)
      for_ar_scope(args, options)
    end

    def find_ids_with(args, options)
      for_ar_scope(args, options.merge(just_ids: true))
    end

    def for_ar_scope(args, options = {})
      ar_type = index.event_stream.record_type
      index_scope = index.ar_scope_proc.call(*args)
      self.class.for_ar_scope(ar_type, index_scope, options)
    end

    def self.for_ar_scope(ar_type, index_scope, options)
      index_scope = index_scope.where(created_at: options[:oldest]..) if options[:oldest].present?
      index_scope = index_scope.where(created_at: ..options[:newest]) if options[:newest].present?
      index_scope = index_scope.select(:id, :created_at) if options[:just_ids] == true
      event_bookmarker = EventStream::IndexStrategy::ActiveRecord::Bookmarker.new(ar_type)
      BookmarkedCollection.build(event_bookmarker) do |pager|
        records = pager_to_records(index_scope, pager)
        pager.replace(records)
        pager.has_more! if records.next_page
        pager
      end
    end

    def self.pager_to_records(index_scope, pager)
      bookmark_scope = index_scope
      if (bookmark = pager.current_bookmark)
        if bookmark.is_a?(Array)
          # New format: stable sorting with [timestamp, id]
          # Arrays are comparable, which is required for cross-shard bookmark merging
          parsed_time = Time.zone.parse(bookmark[0])
          bookmark_id = bookmark[1]
          bookmark_scope = bookmark_scope.where(
            "(created_at < ? OR (created_at = ? AND id < ?))",
            parsed_time,
            parsed_time,
            bookmark_id
          )
        else
          # Legacy format: timestamp only (may have sorting issues but won't break)
          bookmark_scope = bookmark_scope.where(created_at: ...Time.zone.parse(bookmark))
        end
      end
      bookmark_scope = bookmark_scope.order(created_at: :desc, id: :desc)
      bookmark_scope.paginate(page: 1, per_page: pager.per_page)
    end

    class Bookmarker
      def initialize(ar_type)
        @ar_type = ar_type
      end

      def bookmark_for(object)
        # Return an array [timestamp, id] instead of just timestamp for stable sorting.
        # Arrays are comparable in Ruby (element-by-element comparison), which is
        # required for BookmarkedCollection.merge to correctly interleave records
        # from multiple shards when doing cross-shard queries.
        [object.created_at.to_s, object.id]
      end

      def validate(bookmark)
        if bookmark.is_a?(Array)
          # New format: [timestamp, id] array for stable sorting
          bookmark.size == 2 &&
            bookmark[0].is_a?(String) &&
            Time.zone.parse(bookmark[0]).present? &&
            bookmark[1].is_a?(Integer)
        elsif bookmark.is_a?(String)
          # Legacy format: just timestamp string for backward compatibility
          Time.zone.parse(bookmark).present?
        else
          false
        end
      rescue
        false
      end
    end
  end
end
