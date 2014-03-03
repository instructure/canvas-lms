#
# Copyright (C) 2012 Instructure, Inc.
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

class BookmarkedCollection::WrapProxy < BookmarkedCollection::Proxy
  def initialize(bookmarker, base_scope)
    super bookmarker, lambda{ |pager|
      scope = base_scope
      scope = bookmarker.restrict_scope(scope, pager)
      scope = yield scope if block_given?
      scope.paginate(:page => 1, :per_page => pager.per_page, :total_entries => scope.except(:group).count)
    }
  end

  def execute_pager(pager)
    output_pager = super pager
    pager.replace output_pager
    pager.has_more! if output_pager.next_page
    pager
  end
end
