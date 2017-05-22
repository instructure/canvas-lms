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

# extension points for plugins to add sidebar links
# return an array of hashes containing +url+, +icon_class+, and +text+
module CustomSidebarLinksHelper

  # add a link to the account page sidebar
  # @account is the account
  def account_custom_links
    []
  end

  # add a link to the course page sidebar
  # @context is the course
  def course_custom_links
    []
  end

  # add a link to a user roster or profile page
  # @context is the course
  def roster_user_custom_links(user)
    []
  end

end
