#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative '../../common'

module UserProfilePage
    # ---------------------- Selectors ----------------------


    # ---------------------- Elements ----------------------

    def merge_with_another_user_link
      f('a.merge_user_link')
    end

    def search_username_input
      f('.account_search input.user_name')
    end

    def search_userid_input
      f('#manual_user_id')
    end

    def username_search_suggestions
      wait_for_ajaximations
      f('ul.ui-autocomplete')
    end

    def choose_suggested_username(user_name)
      fj("a:contains('#{user_name}')")
    end

    def selected_user
      f('#selected_name')
    end

    def select_user_button
      f('#select_name')
    end

    def merge_user_page_application_div
      f("#application")
    end

    # ------------------ Actions & Methods -------------------

    def visit_merge_user_accounts(user_id)
      get "/users/#{user_id}/admin_merge"
    end
end
