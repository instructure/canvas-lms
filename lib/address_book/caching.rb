module AddressBook

  # lets us keep a cache of results we've already looked up. so e.g. a bulk
  # fetch like known_users or search_users will fill this cache, and then when
  # making queries about individual users already included in that load, we
  # just reuse the cached value.
  module Caching
    class Cache
      def initialize
        @entries = {}
      end

      def key(recipient)
        Shard.global_id_for(recipient)
      end

      def null(users)
        users.each do |user|
          @entries[key(user)] = nil
        end
      end

      def store(known)
        known.each do |user|
          @entries[key(user)] = user
        end
      end

      def cached?(user)
        @entries.has_key?(key(user))
      end

      def fetch(user)
        @entries[key(user)]
      end
    end

    # implementation should return a paginatable collection. this just proxies
    # most calls to it. however, after executing the pager, we want to capture
    # the results in the cache before returning them
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
        @cache.store(pager)
        pager
      end

      def depth
        @collection.depth
      end
    end

    def initialize(sender)
      super(sender)
      @cache = Cache.new
    end

    def cached?(user)
      @cache.cached?(user)
    end

    def known_users(users, options={})
      uncached = users.select{ |user| !cached?(user) }
      # flag excluded users as "not known" so we don't recheck them
      # individually in the future
      @cache.null(uncached)
      @cache.store(super(uncached, options))
      users.map{ |user| @cache.fetch(user) }.compact
    end

    def known_in_context(context, is_admin=false)
      known = super(context, is_admin)
      @cache.store(known)
      known
    end

    def search_users(options={})
      collection = super(options)
      Collection.new(collection, @cache)
    end

    def preload_users(users)
      key = users.map{ |user| Shard.global_id_for(user) }.join(',')
      # still load _all_, not just those missing from in process cache, on
      # rails cache miss, to be consistent with the cache key (and to let the
      # cache key stay consistent across calls e.g. from the same conversation)
      loaded = Rails.cache.fetch([@sender, 'address_book_preload', key].cache_key) do
        super(users)
      end
      # but then prefer in-process cache over rails cache. if they differ, we
      # can pretty much guarantee the in-process cache is fresher.
      newly_loaded = loaded.select{ |user| !cached?(user) }
      @cache.store(newly_loaded)
    end
  end
end
