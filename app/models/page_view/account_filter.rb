#
# Copyright (C) 2017 - present Instructure, Inc.
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

class PageView
  class AccountFilter
    def self.filter(collection, viewer)
      BookmarkedCollection.filter(collection, &new(viewer).method(:filter))
    end

    def initialize(viewer)
      @viewer = viewer
      @accounts = {}
    end

    def filter(pv)
      return true if pv.account_id.nil?
      return @accounts[pv.account_id] if @accounts.key?(pv.account_id)
      # this weird chain is to efficiently check if the user has access to
      # view statistics in any sub account of the given root account
      @accounts[pv.account_id] = pv.account.
        all_account_users_for(@viewer).
        map(&:account).uniq.
        any? { |au| au.grants_any_right?(@viewer, :view_statistics, :manage_students) }
    end
  end
end
