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
    def known_users(_users, *)
      []
    end

    def common_courses(_user)
      {}
    end

    def common_groups(_user)
      {}
    end

    def known_in_context(_context)
      []
    end

    def count_in_contexts(_contexts)
      {}
    end

    module Bookmarker
      def self.bookmark_for(_user)
        "unused"
      end

      def self.validate(_bookmark)
        true
      end
    end

    def search_users(**)
      BookmarkedCollection.build(Bookmarker) { |pager| pager }
    end

    def preload_users(_users)
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
