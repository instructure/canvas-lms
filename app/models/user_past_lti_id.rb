# frozen_string_literal: true

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
#
#
#
# What is a past lti id and why do we have it.
# when a user_a is merged into user_b, user_a is deleted, and user_b remains
# active. Now any courses, groups, or accounts
# that user_a was in at the time of the merge will get a past_lti_id.
#
# => UserPastLtiId(id: integer, user_id: integer, context_id: integer, context_type: string,
#    user_uuid: string, user_lti_id: text, user_lti_context_id: string)
#
# On the past_lti_id we store uuid, lti_id, lti_context_id for a user in a context.
#
# Anytime user_b launches an lti_tool from a context that user_a was a member of,
# they will get the past_lti_ids for user_a even if both user_a and user_b were
# members of that context. In that case we wouldn't know that user_b was there
# prior and we always serve a past_lti_id if there is one present.
#
# This is happening because when a user is merged lti_tools may break or stop
# working because they were using one of those ids as the unique identifier for
# the lti_launch and it could break the lti_tool for the user.
#
# All past_lti_ids are stored on the same shard as the context so that a user
# can always be looked up from the context's shard.
#
class UserPastLtiId < ActiveRecord::Base
  belongs_to :user
  belongs_to :context, polymorphic: %i[account course group]

  # regular pre-loaders will not work because they will load past_lti_ids for
  # the user in all contexts instead of just the context we want.
  # most of these should be nil, because they only exists as the result of a
  # user_merge, but we still want to avoid the N+1
  def self.manual_preload_past_lti_ids(objects, object_context)
    # collaborators are allowed to not have a user, so we compact them here.
    users = objects.first.is_a?(User) ? objects : objects.filter_map(&:user)
    past_lti_ids = UserPastLtiId.where(user_id: users, context: object_context).group_by(&:user_id)
    users.each do |user|
      past_lti_id = past_lti_ids[user.id]
      association = user.association(:past_lti_ids)
      association.loaded!
      past_lti_id = UserPastLtiId.none if past_lti_id.nil?
      association.target.concat(past_lti_id)
      past_lti_id.each { |lti_id| association.set_inverse_instance(lti_id) }
    end
  end

  def self.uuid_for_user_in_context(user, context)
    if user && context
      context.shard.activate do
        user.past_lti_ids.where(context:).take&.user_uuid || user.uuid
      end
    else
      user.uuid
    end
  end
end
