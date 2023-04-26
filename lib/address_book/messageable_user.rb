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
  # implementation of AddressBook interface backed by MessageableUser
  class MessageableUser < AddressBook::Base
    def known_users(users, options = {})
      options = { strict_checks: true }.merge(options)
      if options[:context]
        user_ids = users.to_set { |user| Shard.global_id_for(user) }
        asset_string = options[:context].respond_to?(:asset_string) ? options[:context].asset_string : options[:context]
        known_users = @sender.messageable_user_calculator
                             .messageable_users_in_context(asset_string, admin_context: admin_context?(options[:context]))
                             .select { |user| user_ids.include?(user.global_id) }

        # group members who are in different sections will not be included by
        # the logic above; if the context is a course, we must check if there
        # are any group members who need to be included as known users
        if options[:context].is_a?(Course) && options[:context].groups.present?
          # retrieve only the groups that belong to the course and that the
          # sender belongs to
          groups = @sender.groups.merge(options[:context].groups)
          groups.each do |group|
            group_members = @sender.messageable_user_calculator
                                   .messageable_users_in_group(group)
                                   .select { |user| user_ids.include?(user.global_id) }
            known_users.concat(group_members).uniq
          end
        end
      else
        # in case we were handed something that's already a messageable user,
        # pass it in as just the id so we don't modify it in place
        # (MessageableUser was original built to want that optimization, but
        # now we don't)
        users = users.map(&:id) if users.first.is_a?(::MessageableUser)
        known_users = @sender.load_messageable_users(users, conversation_id: options[:conversation_id], strict_checks: options[:strict_checks])
      end
      known_users.each { |user| @cache.store(user, user.common_courses, user.common_groups) }
      known_users
    end

    def known_in_context(context)
      asset_string = context.respond_to?(:asset_string) ? context.asset_string : context
      known_users = @sender.messageable_users_in_context(asset_string)
      known_users.each { |user| @cache.store(user, user.common_courses, user.common_groups) }
      known_users
    end

    def count_in_contexts(contexts)
      counts = {}
      contexts.each do |context|
        counts[context] =
          @sender.count_messageable_users_in_context(
            context,
            admin_context: admin_context?(context)
          )
      end
      counts
    end

    # search_messageable_users returns a paginatable collection. this just
    # proxies most calls to it. however, after executing the pager, we want to
    # capture the results in the cache before returning them
    class Collection
      def initialize(collection, cache)
        @collection = collection
        @cache = cache
      end

      def paginate(options = {})
        execute_pager(configure_pager(new_pager, options))
      end

      def new_pager
        @collection.new_pager
      end

      def configure_pager(pager, options)
        @collection.configure_pager(pager, options)
      end

      def execute_pager(pager)
        @collection.execute_pager(pager)
        pager.each { |user| @cache.store(user, user.common_courses, user.common_groups) }
        pager
      end

      def depth
        @collection.depth
      end
    end

    def search_users(options = {})
      asset_string = options[:context].respond_to?(:asset_string) ? options[:context].asset_string : options[:context]
      collection = @sender.search_messageable_users(
        search: options[:search],
        exclude_ids: options[:exclude_ids],
        context: asset_string,
        admin_context: admin_context?(options[:context]),
        strict_checks: !options[:weak_checks]
      )
      Collection.new(collection, @cache)
    end

    def preload_users(users)
      # in case we were handed something that's already a messageable user,
      # pass it in as just the id so we don't modify it in place
      # (MessageableUser was original built to want that optimization, but
      # now we don't)
      users = users.map(&:id) if users.first.is_a?(::MessageableUser)

      # still load _all_, not just those missing from in process cache, on
      # rails cache miss, to be consistent with the cache key (and to let the
      # cache key stay consistent across calls e.g. from the same conversation)
      key = users.map { |user| Shard.global_id_for(user) }.join(",")
      loaded = Rails.cache.fetch([@sender, "address_book_preload", key].cache_key) do
        @sender.load_messageable_users(users, strict_checks: false)
      end

      # but then prefer in-process cache over rails cache. if they differ, we
      # can pretty much guarantee the in-process cache is fresher.
      newly_loaded = loaded.reject { |user| cached?(user) }
      newly_loaded.each { |user| @cache.store(user, user.common_courses, user.common_groups) }
    end
  end
end
