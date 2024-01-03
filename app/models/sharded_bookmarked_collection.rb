# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  def self.build(bookmarker, relation, always_use_bookmarks: false)
    # automatically make associations multi-shard, since that's definitely what you want if you're
    # using this
    if (owner = relation.respond_to?(:proxy_association) && relation.proxy_association&.owner)
      relation = relation.shard(owner)
    end
    # not the result of relation.activate because we don't want it to
    # flatten our list of pairs
    collections = []
    # get the per-shard relations
    last_relation = nil
    relation.activate do |sharded_relation|
      sharded_relation = yield sharded_relation if block_given?
      # if they returned nil, there was nothing pertinent on this shard anyway, so completely skip it
      next if sharded_relation.nil?

      last_relation = sharded_relation
      collections << [Shard.current.id, BookmarkedCollection.wrap(bookmarker, sharded_relation)]
      nil
    end
    # optimization if there ended up being none
    return relation.none if collections.empty?
    # optimization if there only ended up being one
    return always_use_bookmarks ? collections.last.last : last_relation if collections.size == 1

    BookmarkedCollection.merge(*collections)
  end
end
