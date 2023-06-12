# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module AddressBook
  class Service < AddressBook::Base
    def initialize(sender, ignore_result: false)
      super(sender)
      @ignore_result = ignore_result
    end

    def known_users(users, options = {})
      return [] if users.empty?

      user_ids = users.map { |user| Shard.global_id_for(user) }

      if admin_context?(options[:context])
        # users any admin over the specified context knows
        common_contexts = Services::AddressBook.roles_in_context(options[:context], user_ids, @ignore_result)
      elsif options[:context]
        # any of the users I know through the specified context
        _, common_contexts = Services::AddressBook.known_in_context(@sender, options[:context], user_ids, @ignore_result)
      else
        # any of the users I know at all
        common_contexts = Services::AddressBook.common_contexts(@sender, user_ids, @ignore_result)
      end

      # whitelist just those users I know
      whitelist, unknown = user_ids.partition { |id| common_contexts.key?(id) }
      if unknown.present? && options[:conversation_id].present?
        conversation_shard = Shard.shard_for(options[:conversation_id])
        participants = ConversationParticipant.shard(conversation_shard).where(
          conversation_id: options[:conversation_id],
          user_id: [@sender, *unknown]
        ).pluck(:user_id)
        if participants.include?(@sender.id)
          # add conversation participants to whitelist
          whitelist |= participants.map { |id| Shard.global_id_for(id) }
        end
      end

      # apply whitelist to provided user objects/ids, to restore order
      users.select! { |user| whitelist.include?(Shard.global_id_for(user)) }

      # if we didn't start with objects, hydrate
      users = hydrate(users) unless users.first.is_a?(User)

      # cache and return
      cache_contexts(users, common_contexts) unless @ignore_result
      users
    end

    def known_in_context(context)
      # just query, hydrate, and cache
      user_ids, common_contexts = Services::AddressBook.known_in_context(@sender, context, nil, @ignore_result)
      users = hydrate(user_ids)
      cache_contexts(users, common_contexts) unless @ignore_result
      users
    end

    def count_in_contexts(contexts)
      Services::AddressBook.count_in_contexts(@sender, contexts, @ignore_result)
    end

    class Bookmarker
      def initialize
        @cursors = {}
        @more = false
      end

      def update(user_ids, cursors)
        @cursors = user_ids.zip(cursors).to_h
        @more = !!@cursors[user_ids.last]
      end

      def more?
        @more
      end

      def bookmark_for(user)
        @cursors[user.global_id]
      end

      def validate(bookmark)
        bookmark.is_a?(Integer) && bookmark >= 0
      end
    end

    def search_users(options = {})
      # if we're querying a specific context and that context is a valid admin
      # context for the sender, then we want the sender-agnostic search results
      # (i.e. the results any admin would see). otherwise, include the sender
      # to tailor the search results
      sender = admin_context?(options[:context]) ? nil : @sender
      bookmarker = Bookmarker.new
      BookmarkedCollection.build(bookmarker) do |pager|
        # include bookmark info in service call if necessary
        service_options = { per_page: pager.per_page }
        if pager.current_bookmark
          if pager.include_bookmark
            # don't raise the exception; there's no place better to handle it
            # than here. handling it is just complaining in an error report,
            # and then ignoring
            Canvas::Errors.capture(RuntimeError.new(
                                     "AddressBook::Service#search_users should not be paged with include_bookmark: true"
                                   ),
                                   {},
                                   :warn)
          end
          service_options[:cursor] = pager.current_bookmark
        end

        # query, hydrate, and cache
        user_ids, common_contexts, cursors = Services::AddressBook.search_users(sender, options, service_options, @ignore_result)
        bookmarker.update(user_ids, cursors)
        users = hydrate(user_ids)
        cache_contexts(users, common_contexts) unless @ignore_result

        # place results in pager
        pager.replace(users)
        pager.has_more! if bookmarker.more?
        pager
      end
    end

    def preload_users(users)
      return if users.empty?

      # make sure we're dealing with user objects
      users = hydrate(users) unless users.first.is_a?(User)

      # query only those directly known, but all are "whitelisted" for caching
      global_user_ids = users.map(&:global_id)
      common_contexts = Services::AddressBook.common_contexts(@sender, global_user_ids, @ignore_result)
      cache_contexts(users, common_contexts) unless @ignore_result
    end

    private

    # takes a list of user ids and returns a corresponding list of objects,
    # order preserved.
    def hydrate(ids)
      ids = ids.map { |id| Shard.global_id_for(id) }
      hydrated = User.select(::MessageableUser::SELECT).where(id: ids)
      reverse_lookup = hydrated.index_by(&:global_id)
      ids.filter_map { |id| reverse_lookup[id] }
    end

    # caches with common contexts for each user in the list, pulling the
    # results from the provided array, defaulting to empty hashes (none, but
    # user still whitelisted)
    def cache_contexts(users, common_contexts)
      users.each do |user|
        contexts = common_contexts[user.global_id]
        courses = contexts ? contexts[:courses] : {}
        groups = contexts ? contexts[:groups] : {}
        @cache.store(user, courses, groups)
      end
    end
  end
end
