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

# Custom GraphQL connection for BookmarkedCollection::Proxy.
#
# Cursors are page-level, not per-item — BookmarkedCollection doesn't expose
# bookmark_for(item), so cursor_for returns the *next page's* bookmark for
# every item on the current page. Consequences:
#
#   - Forward pagination (first/after/endCursor/hasNextPage) works correctly
#   - endCursor is nil on the last page (consistent with hasNextPage: false)
#   - startCursor equals endCursor (unavoidable without per-item bookmarks)
#   - Edge cursors are all identical within a page
#   - Backward pagination (last/before) is not supported
#
# Cursors pass through without encoding: cursor_for returns a raw bookmark
# string like "bookmark:W1tdXQ" directly to the client, and the client sends
# it back as-is via `after`. No base64 layer — encoding is opt-in per
# Connection subclass (via encode/decode), and we don't use it.
class CollectionConnection < GraphQL::Pagination::Connection
  def cursor_for(_item)
    @next_page
  end

  def has_next_page
    !!@next_page
  end

  def has_previous_page
    !!after
  end

  def nodes
    @nodes ||= begin
      batch = items.paginate(page: after, per_page: first || 100)
      @next_page = batch.next_page
      batch
    end
  end
end
