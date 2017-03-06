module AddressBook
  class PerformanceTap < AddressBook::MessageableUser
    def initialize(sender)
      super sender
      @service_tap = AddressBook::Service.new(sender, ignore_result: true)
    end

    def known_users(users, options={})
      @service_tap.known_users(users, options)
      super
    end

    def known_in_context(context, is_admin=false)
      @service_tap.known_in_context(context, is_admin)
      super
    end

    def count_in_context(context)
      @service_tap.count_in_context(context)
      super
    end

    # makes a wrapper around two paginated collections, one for source and one
    # for the tap. proxies pagination information and results to and from the
    # source collection, but also executes pagination against the tap
    # collection for every source page.
    class TapProxy < PaginatedCollection::Proxy
      def initialize(source_collection:, tap_collection:)
        @source_collection = source_collection
        super lambda{ |source_pager|
          tap_pager = tap_collection.configure_pager(
            tap_collection.new_pager,
            per_page: source_pager.per_page,
            total_entries: nil
          )
          tap_collection.execute_pager(tap_pager)
          source_collection.execute_pager(source_pager)
        }
      end

      def depth
        @source_collection.depth
      end

      def new_pager
        @source_collection.new_pager
      end

      def configure_pager(pager, options)
        @source_collection.configure_pager(pager, options)
      end
    end

    def search_users(options={})
      TapProxy.new(
        source_collection: super,
        tap_collection: @service_tap.search_users(options)
      )
    end

    def preload_users(users)
      @service_tap.preload_users(users)
      super
    end
  end
end
