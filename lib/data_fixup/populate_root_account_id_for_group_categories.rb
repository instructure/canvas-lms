#
# Copyright (C) 2011 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdForGroupCategories
  def self.run
    # A context_type is now required; however, earlier, it wasn't. So there could
    # be some GroupCategory records that don't have a context_type. This only
    # looks for ones that do have a context_type, since we use that to find what
    # account it belongs to.
    GroupCategory.where(root_account_id: nil).where.not(context_type: nil).find_each do |group_category|
      root_account_id = group_category.context&.root_account&.id
      group_category.update!(root_account_id: root_account_id) if root_account_id
    end
  end
end
