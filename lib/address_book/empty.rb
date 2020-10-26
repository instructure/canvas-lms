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

    def known_in_context(context)
      []
    end

    def count_in_contexts(contexts)
      {}
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
