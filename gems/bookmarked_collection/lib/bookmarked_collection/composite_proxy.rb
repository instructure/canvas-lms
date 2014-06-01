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

class BookmarkedCollection::CompositeProxy < BookmarkedCollection::Proxy
  attr_reader :collections

  def initialize(collections)
    @labels = collections.map(&:first)
    @depth = collections.map{ |(_,coll)| coll.depth }.max + 1
    @collections = collections.map do |(label,coll)|
      adjustment = @depth - 1 - coll.depth
      adjustment.times.inject(coll) { |c,i| BookmarkedCollection.concat([label, c]) }
    end
  end

  def new_pager
    BookmarkedCollection::CompositeCollection.new(@depth, @labels)
  end
end
