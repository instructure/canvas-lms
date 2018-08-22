#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::MembershipService
  class CollatorBase
    attr_reader :next_page

    def initialize
      @next_page = true
    end

    def next_page?
      @next_page.present?
    end

    def memberships
      raise 'Abstract Method'
    end

    protected

    def scope
      raise 'Abstract Method'
    end

    def membership_type
      raise 'Abstract Method'
    end

    def bookmarked_collection
      @_bookmarked_collection ||= begin
        bookmarker = BookmarkedCollection::SimpleBookmarker.new(membership_type, :id)
        BookmarkedCollection.build(bookmarker) do |pager|
          bookmarker_scope = bookmarker.restrict_scope(scope, pager)
          page = bookmarker_scope.paginate(page: @page, per_page: pager.per_page)
          @next_page = page.next_page
          page
        end
      end
    end
  end
end
