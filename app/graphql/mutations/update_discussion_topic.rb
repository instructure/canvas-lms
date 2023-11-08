# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::UpdateDiscussionTopic < Mutations::DiscussionBase
  graphql_name "UpdateDiscussionTopic"

  argument :discussion_topic_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionTopic")

  field :discussion_topic, Types::DiscussionType, null: false
  def resolve(input:)
    discussion_topic = DiscussionTopic.find(input[:discussion_topic_id])
    raise GraphQL::ExecutionError, "insufficient permission" unless discussion_topic.grants_right?(current_user, :update)

    unless input[:published].nil?
      input[:published] ? discussion_topic.publish! : discussion_topic.unpublish!
    end

    unless input[:locked].nil?
      input[:locked] ? discussion_topic.lock! : discussion_topic.unlock!
    end

    set_sections(input[:specific_sections], discussion_topic)
    invalid_sections = verify_specific_section_visibilities(discussion_topic) || []

    unless invalid_sections.empty?
      return validation_error(I18n.t("You do not have permissions to modify discussion for section(s) %{section_ids}", section_ids: invalid_sections.join(", ")))
    end

    process_common_inputs(input, discussion_topic.is_announcement, discussion_topic)
    process_future_date_inputs(input[:delayed_post_at], input[:lock_at], discussion_topic)

    return errors_for(discussion_topic) unless discussion_topic.save

    {
      discussion_topic:
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
