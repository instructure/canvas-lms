#
# Copyright (C) 2011 Instructure, Inc.
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

def group_model(opts={})
  @group = factory_with_protected_attributes(Group, valid_group_attributes.merge(opts))
end

def valid_group_attributes
  {
    :name => 'value for name',
    :context => Account.default
  }
end

VALID_GROUP_ATTRIBUTES = [:name, :context, :max_membership, :group_category, :join_level, :description, :is_public, :avatar_attachment]

def group(opts={})
  context = opts[:group_context] || opts[:context] || Account.default
  @group = context.groups.create! opts.slice(*VALID_GROUP_ATTRIBUTES)
end

def group_with_user(opts={})
  group(opts)
  u = opts[:user] || user(opts)
  workflow_state = opts[:active_all] ? 'accepted' : nil
  @group.add_user(u, workflow_state, opts[:moderator])
end

def group_with_user_logged_in(opts={})
  group_with_user(opts)
  user_session(@user)
end
