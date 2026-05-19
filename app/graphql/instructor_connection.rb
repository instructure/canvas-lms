# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class InstructorConnection < GraphQL::Pagination::Connection
  def nodes
    load_page
    @nodes
  end

  # rubocop:disable Naming/PredicateMethod, Naming/PredicatePrefix
  def has_next_page
    load_page
    @has_next_page
  end

  def has_previous_page
    offset > 0
  end
  # rubocop:enable Naming/PredicateMethod, Naming/PredicatePrefix

  def cursor_for(item)
    idx = nodes.index(item) || 0
    encode((offset + idx + 1).to_s)
  end

  def total_count
    @total_count ||= items.total_count
  end

  private

  def load_page
    return if @page_loaded

    results = items.fetch_page(page_size + 1, offset)
    @has_next_page = results.length > page_size
    @nodes = @has_next_page ? results[0...page_size] : results
    @page_loaded = true
  end

  def page_size
    first || last || 5
  end

  def offset
    @offset ||= if after
                  decode(after).to_i
                elsif before
                  [decode(before).to_i - page_size, 0].max
                else
                  0
                end
  end
end
