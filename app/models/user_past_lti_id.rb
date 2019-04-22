#
# Copyright (C) 2019 - present Instructure, Inc.
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
class UserPastLtiId < ActiveRecord::Base
  belongs_to :user
  belongs_to :context, polymorphic: [:account, :course, :group]

  # regular pre-loaders will not work because they will load past_lti_ids for
  # the user in all contexts instead of just the context we want.
  # most of these should be nil, because they only exists as the result of a
  # user_merge, but we still want to avoid the N+1
  def self.manual_preload_past_lti_ids(objects, object_context)
    # collaborators are allowed to not have a user, so we compact them here.
    users = objects.first.is_a?(User) ? objects : objects.map(&:user).compact
    past_lti_ids = UserPastLtiId.where(user_id: users, context: object_context).group_by(&:user_id)
    users.each do |user|
      past_lti_id = past_lti_ids[user.id]
      association = user.association(:past_lti_ids)
      association.loaded!
      past_lti_id = past_lti_id.nil? ? UserPastLtiId.none : past_lti_id
      association.target.concat(past_lti_id)
      past_lti_id.each {|lti_id| association.set_inverse_instance(lti_id)}
    end
  end

  def self.uuid_for_user_in_context(user, context)
    if user && context
      context.shard.activate do
        user.past_lti_ids.where(context: context).take&.user_uuid || user.uuid
      end
    else
      user.uuid
    end
  end
end
