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

module Factories
  def group_membership_model(opts={})
    do_save = opts.has_key?(:save) ? opts.delete(:save) : true
    @group_membership = factory_with_protected_attributes(GroupMembership, valid_group_membership_attributes.merge(opts), do_save)
  end

  def valid_group_membership_attributes
    {
      :group => @group,
      :user => @user
    }
  end
end
