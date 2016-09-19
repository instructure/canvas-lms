module AddressBook

  # implementation of AddressBook interface backed by MessageableUser
  class MessageableUser < AddressBook::Base
    def known_users(users, options={})
      # in case we were handed something that's already a messageable user,
      # pass it in as just the id so we don't modify it in place
      # (MessageableUser was original built to want that optimization, but
      # now we don't)
      users = users.map(&:id) if users.first.is_a?(::MessageableUser)
      known_users = @sender.load_messageable_users(users,
        admin_context: options[:include_context],
        conversation_id: options[:conversation_id])
      known_users.each{ |user| @cache.store(user, user.common_courses, user.common_groups) }
      known_users
    end

    def known_in_context(context, is_admin=false)
      admin_context = context if is_admin
      known_users = @sender.
        messageable_user_calculator.
        messageable_users_in_context(context, admin_context: admin_context)
      known_users.each{ |user| @cache.store(user, user.common_courses, user.common_groups) }
      known_users
    end

    def count_in_context(context)
      @sender.count_messageable_users_in_context(context)
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
        pager.each{ |user| @cache.store(user, user.common_courses, user.common_groups) }
        pager
      end

      def depth
        @collection.depth
      end
    end

    def search_users(options={})
      collection = @sender.search_messageable_users(
        search: options[:search],
        exclude_ids: options[:exclude_ids],
        context: options[:context],
        admin_context: options[:context] && options[:is_admin],
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
      key = users.map{ |user| Shard.global_id_for(user) }.join(',')
      loaded = Rails.cache.fetch([@sender, 'address_book_preload', key].cache_key) do
        @sender.load_messageable_users(users, strict_checks: false)
      end

      # but then prefer in-process cache over rails cache. if they differ, we
      # can pretty much guarantee the in-process cache is fresher.
      newly_loaded = loaded.select{ |user| !cached?(user) }
      newly_loaded.each{ |user| @cache.store(user, user.common_courses, user.common_groups) }
    end
  end
end
