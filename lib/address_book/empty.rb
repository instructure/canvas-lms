module AddressBook
  # trivially empty implementation of AddressBook interface. useful for
  # demonstrating the bare minimum of the type contract -- returns the right
  # shapes but no data -- while being separate from the original
  # MessageableUser strategy.
  class Empty < AddressBook::Base
    def known_users(users, options={})
      []
    end

    def common_courses(user)
      {}
    end

    def common_groups(user)
      {}
    end

    def known_in_context(context, is_admin=false)
      []
    end

    def count_in_context(context)
      0
    end

    module Bookmarker
      def self.bookmark_for(user)
        'unused'
      end

      def self.validate(bookmark)
        true
      end
    end

    def search_users(options={})
      BookmarkedCollection.build(Bookmarker) { |pager| pager }
    end

    def preload_users(users)
      []
    end

    def sections
      []
    end

    def groups
      []
    end
  end
end
