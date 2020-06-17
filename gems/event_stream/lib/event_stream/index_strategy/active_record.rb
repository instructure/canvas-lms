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

    def insert(_record, _key)
      # no-op because the DB has indexes
    end

    def find_with(args, options)
      for_ar_scope(args, options)
    end

    def find_ids_with(args, options)
      for_ar_scope(args, options.merge(just_ids: true))
    end

    def for_ar_scope(args, options={})
      ar_type = index.event_stream.active_record_type
      index_scope = ar_type.where(index.ar_conditions_proc.call(*args))
      index_scope = index_scope.where("created_at >= ?", options[:oldest]) if options[:oldest].present?
      index_scope = index_scope.where("created_at <= ?", options[:newest]) if options[:newest].present?
      index_scope = index_scope.select(:id, :created_at) if options[:just_ids] == true
      event_bookmarker = EventStream::IndexStrategy::ActiveRecord::Bookmarker.new(ar_type)
      bookmarked_collection = BookmarkedCollection.build(event_bookmarker) do |pager|
        records = pager_to_records(index_scope, pager)
        pager.replace(records)
        pager.has_more! if records.next_page
        pager
      end
    end

    def pager_to_records(index_scope, pager)
      bookmark_scope = index_scope
      if bookmark = pager.current_bookmark
        bookmark_scope = bookmark_scope.where("created_at < ?", Time.zone.parse(bookmark))
      end
      bookmark_scope = bookmark_scope.order("created_at DESC")
      bookmark_scope.paginate(page: 1, per_page: pager.per_page)
    end

    class Bookmarker
      def initialize(ar_type)
        @ar_type = ar_type
      end

      def bookmark_for(object)
        object.created_at.to_s
      end

      def validate(bookmark)
        bookmark.is_a?(String) && Time.zone.parse(bookmark).present?
      end
    end
  end
end