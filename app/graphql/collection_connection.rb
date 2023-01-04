# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CollectionConnection < GraphQL::Pagination::Connection
  def cursor_for(*)
    @next_page
  end

  def has_next_page
    !!@next_page
  end

  def nodes
    if first
      batch = items.paginate(page: after, per_page: first)
      @next_page = batch.next_page
      batch
    else
      # This is not very performant, but i'm not sure how else to get all items from a BookmarkedCollection
      # As a result these connections should really only be used if they are paginated
      users = []
      if items
        batch = items.paginate(per_page: 100)
        users += batch
        while batch.next_page
          batch = items.paginate(page: batch.next_page, per_page: 100)
          users += batch
        end
      end
      users
    end
  end
end
