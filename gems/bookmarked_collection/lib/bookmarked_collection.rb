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

# Defines a variant on PaginatedCollection where the page identifier is a
# bookmark value, rather than a page number. Advantages of bookmarked
# collections are the ability to combine multiple subcollections into one
# composite collection and still have consistent pagination semantics.
#
# Bookmarks are simple, light-weight data structures uniquely identifying an
# item within a collection. It is important that the bookmark value be small
# and simple, since its serialization will determine the value of the page
# parameter in URLs. Additionally, the bookmark value must be sortable with
# other bookmarks in the same collection, and that ordering must match the
# ordering of the collection.
#
# When dealing with bookmarked collections, the semantics of a pager change
# slightly. Instead of looking at pager.current_page to determine an offset,
# the client should look at pager.current_bookmark and pager.include_bookmark
# to condition the results, and then select the first page of that restricted
# set.
#
# The include_bookmark flag indicates whether the result set should include
# items that map to current_bookmark. Typically it will be false --
# current_bookmark should correspond to the last item on the previous page and
# should not be included in this page. However, when dealing with merged
# collections it's possible for the same bookmark to appear in multiple
# subcollections. For example, if:
#
#  * collections A and B are merged,
#  * each has an item corresponding to a bookmark value X,
#  * the item from A is included the previous page of results,
#  * but the item from B needs to be included in the current page
#
# The pager fed into collection A will have bookmark X and include_bookmark set
# false, but the pager fed into collection B will have bookmark X and
# include_bookmark set true.
#
# On the other end, for a bookmarked collection you are no longer responsible
# for setting next_page (or previous_page or last_page, which are unsupported).
# Instead, an invocation of pager.has_more! will automatically determine the
# bookmark value of the last item in the collection and set next_bookmark and,
# from that, next_page.
#

require 'folio/rails'
require 'folio/page'
require 'paginated_collection'
require 'json_token'

if CANVAS_RAILS3
  require 'will_paginate/active_record'
else
  require 'fake_arel'
end

module BookmarkedCollection
  require 'bookmarked_collection/collection'
  require 'bookmarked_collection/composite_collection'
  require 'bookmarked_collection/proxy'
  require 'bookmarked_collection/composite_proxy'
  require 'bookmarked_collection/concat_collection'
  require 'bookmarked_collection/concat_proxy'
  require 'bookmarked_collection/merge_proxy'
  require 'bookmarked_collection/simple_bookmarker'
  require 'bookmarked_collection/wrap_proxy'

  def self.best_unicode_collation_key(col)
    if @best_unicode_collation_key_proc
      @best_unicode_collation_key_proc.call(col)
    else
      col
    end
  end

  def self.best_unicode_collation_key_proc=(value)
    @best_unicode_collation_key_proc = value
  end

  # Analogous to PaginatedCollection.build. The provided bookmarker object
  # must respond to bookmark_for and validate:
  #
  #  - bookmarker.bookmark_for(item): should translate an item as it will
  #    appear in the collection into a bookmark value.
  #
  #  - bookmarker.validate(bookmark): should validate an incoming bookmark
  #    value, since it may have been tampered with or damaged between issuance
  #    and use.
  #
  # As with PaginatedCollection.build, the provided block will receive a pager
  # object. The block should then fill that pager with the appropriate page of
  # results according to pager.current_bookmark and pager.include_bookmark
  # (rather than pager.current_page). Finally, call pager.has_more! iff there
  # is another page of results after; this will automatically set
  # pager.next_bookmark by calling bookmarker.bookmark_for on the last item in
  # the collection.
  #
  # Example:
  #
  #   module UserBookmarker
  #     def self.bookmark_for(user)
  #       user.sortable_name
  #     end
  #
  #     def self.validate(bookmark)
  #       bookmark.is_a?(String)
  #     end
  #   end
  #
  #   base_scope = User.active.order_by_sortable_name
  #   bookmarked_collection = BookmarkedCollection.build(UserBookmarker) do |pager|
  #     if pager.current_bookmark
  #       sortable_name = pager.current_bookmark.to_s
  #       comparison = (pager.include_bookmark ? ">=" : ">")
  #       scope = base_scope.where(
  #         "sortable_name #{comparison} ?",
  #         sortable_name)
  #     end
  #     users = scope.paginate(:page => 1, :per_page => pager.per_page)
  #     pager.replace users
  #     pager.has_more! if users.next_page
  #     pager
  #   end
  #
  #   Api.paginate(bookmarked_collection, ...)
  #
  def self.build(bookmarker, &block)
    BookmarkedCollection::Proxy.new(bookmarker, block)
  end

  # Simplifies the common case of wrapping an ActiveRecord scope in bookmark
  # pagination.
  #
  # The bookmarker object is as for .build with an additional restrict_scope
  # method:
  #
  #  - bookmarker.restrict_scope(scope, pager): should return a new scope based
  #    on scope and restricted according to pager.current_bookmark and
  #    pager.include_bookmark. should typically enforce the scope is ordered by
  #    the bookmark, as well.
  #
  # base_scope is the ActiveRecord scope to wrap. options and block act on the
  # base_scope as in association.with_each_shard.
  #
  # Example:
  #
  #   module UserBookmarker
  #     def self.bookmark_for(user)
  #       user.sortable_name
  #     end
  #
  #     def self.validate(bookmark)
  #       bookmark.is_a?(String)
  #     end
  #
  #     def self.restrict_scope(scope, pager)
  #       if pager.current_bookmark
  #         sortable_name = pager.current_bookmark.to_s
  #         comparison = (pager.include_bookmark ? ">=" : ">")
  #         scope = scope.where(
  #           "sortable_name #{comparison} ?",
  #           sortable_name)
  #       end
  #       scope.order_by_sortable_name
  #     end
  #   end
  #
  #   bookmarked_collection = BookmarkedCollection.wrap(UserBookmarker, User.active)
  #   Api.paginate(bookmarked_collection, ...)
  #
  # Note that if your bookmarker has relatively simple behavior (i.e.
  # just order by one or more columns), you can just instantiate a
  # BookmarkedCollection::SimpleBookmarker. The example above could be
  # simplified like so:
  #
  #   UserBookmarker = BookmarkedCollection::SimpleBookmarker.new(User, :sortable_name)
  #
  #   bookmarked_collection = BookmarkedCollection.wrap(UserBookmarker, User.active)
  #   Api.paginate(bookmarked_collection, ...)
  #
  def self.wrap(bookmarker, base_scope, &block)
    BookmarkedCollection::WrapProxy.new(bookmarker, base_scope, &block)
  end

  # Combines multiple named bookmarked collections into a single collection
  # with a merge sort semantic.
  #
  # If you look at a composite collection as a tree, interior nodes are also
  # composite collections and leaf nodes are considered "leaf collections".
  # The bookmark for a composite collection will include the path through the
  # interior nodes to reach the appropriate leaf collection, and then the
  # bookmark value from that leaf, which is the "leaf bookmark value".
  #
  # All leaf collections in the new merged collection must define bookmarks
  # that are mutually comparable. Beyond comparability, the leaf collections
  # need not share bookmark implementation or semantics; however, the results
  # in the merged collection will be sorted by the leaf bookmark values, so it
  # is useful for there to be semantic correlation in the bookmarks.
  #
  # In cases where a leaf bookmark value is duplicated across immediate child
  # collections in the merged collection, the tie is broken by the collections'
  # positions in the list provided to the merge method. This tiebreaker is
  # automatically incorporated into the merged collection's bookmark and used
  # to inform the value of include_bookmark when processing the subcollections.
  #
  # Alternately, if the merge is provided with a block, duplicate elements
  # across collections will be collapsed down into one element. The block will
  # be yielded to with the kept element (the first instance seen) and the
  # duplicate, allowing the caller to copy any necessary information from the
  # duplicate to the kept element.
  #
  # NOTE: While a hash interface rather than a list of pairs may seem cleaner,
  # we need to preserve order as well as name association, so it's not
  # feasible.
  #
  # Example:
  #
  #   courses = BookmarkedCollection.wrap(CourseBookmarker, Course.active)
  #   users = BookmarkedCollection.wrap(UserBookmarker, User.active)
  #   paginated_collection = BookmarkedCollection.merge(
  #     ['courses', courses],
  #     ['users', users]
  #   )
  #
  def self.merge(*collections, &merge_proc)
    BookmarkedCollection::MergeProxy.new(collections, &merge_proc)
  end

  # Combines multiple named bookmarked collections into a single collection
  # with a concatenation semantic.
  #
  # Unlike a merge, there is no restriction on comparability of leaf
  # collections; no bookmarks are compared cross-collection. (The obvious
  # exception is if you intend to use the concatenated collection as a child in
  # a merged collection.)
  #
  # NOTE: While a hash interface rather than a list of pairs may seem cleaner,
  # we need to preserve order as well as name association, so it's not
  # feasible.
  #
  # Example:
  #
  #   courses = BookmarkedCollection.wrap(CourseBookmarker, Course.active)
  #   users = BookmarkedCollection.wrap(UserBookmarker, User.active)
  #   paginated_collection = SpecificBookmarker.concat(
  #     ['courses', courses],
  #     ['users', users])
  #
  def self.concat(*collections)
    BookmarkedCollection::ConcatProxy.new(collections)
  end
end
