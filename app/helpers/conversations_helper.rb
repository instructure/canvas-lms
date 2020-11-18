# frozen_string_literal: true

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

module ConversationsHelper

  def contexts_for(audience, context_tags)
    result = {:courses => {}, :groups => {}}
    return result if audience.empty?
    context_tags.inject(result) do |hash, tag|
      next unless tag =~ /\A(course|group)_(\d+)\z/
      hash["#{$1}s".to_sym][$2.to_i] = []
      hash
    end

    if audience.size == 1 && include_private_conversation_enrollments
      enrollments = Shard.partition_by_shard(result[:courses].keys) do |course_ids|
        next unless audience.first.associated_shards.include?(Shard.current)
        Enrollment.where(course_id: course_ids, user_id: audience.first.id, workflow_state: 'active').select([:course_id, :type]).to_a
      end
      enrollments.each do |enrollment|
        result[:courses][enrollment.course_id] << enrollment.type
      end

      memberships = Shard.partition_by_shard(result[:groups].keys) do |group_ids|
        next unless audience.first.associated_shards.include?(Shard.current)
        GroupMembership.where(group_id: result[:groups].keys, user_id: audience.first.id, workflow_state: 'accepted').select(:group_id).to_a
      end
      memberships.each do |membership|
        result[:groups][membership.group_id] = ['Member']
      end
    end
    result
  end

end
