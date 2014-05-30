#
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

module ShardedBookmarkedCollection

  # Given an association (+HasManyAssociation+ or +HasManyThroughAssociation+),
  # automatically creates bookmarked collections for the shard-restricted
  # versions of that association (using wrap) and then merges those
  # collections. For parity with the association's +with_each_shard+ methods,
  # you can also provide additional ActiveRecord find options or a scope
  # refinement block.
  #
  # Example:
  #
  #   ShardedBookmarkCollection.build(UserBookmarker, @user.courses)
  #
  #   ShardedBookmarkCollection.build(UserBookmarker, @user.courses) do |scope|
  #     scope.active
  #   end
  #
  def self.build(bookmarker, association)
    # not the result of association.with_each_shard because we don't want it to
    # flatten our list of pairs
    collections = []
    association.with_each_shard do |sharded_association|
      sharded_association = yield sharded_association if block_given?
      collections << [Shard.current.id, BookmarkedCollection.wrap(bookmarker, sharded_association)]
      nil
    end
    BookmarkedCollection.merge(*collections)
  end
end