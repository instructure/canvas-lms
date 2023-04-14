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

module Api::V1::ContentShare
  include Api::V1::Json
  include Api::V1::ContentExport

  # map content export selected-content collection to API-visible content type
  EXPORT_TYPES = {
    "assignments" => "assignment",
    "attachments" => "attachment",
    "discussion_topics" => "discussion_topic",
    "wiki_pages" => "page",
    "quizzes" => "quiz",
    "context_modules" => "module",
    "content_tags" => "module_item"
  }.freeze

  def content_share_json(content_share, user, session, opts = {})
    json = api_json(content_share, user, session, opts.merge(only: %w[id name created_at updated_at user_id read_state]))
    json["sender"] = (content_share.respond_to?(:sender) && content_share.sender) ? user_display_json(content_share.sender) : nil
    json["receivers"] = content_share.respond_to?(:receivers) ? content_share.receivers.map { |rec| user_display_json(rec) } : []
    if content_share.content_export
      json["content_type"] = get_content_type_from_export_settings(content_share.content_export.settings)
      json["content_export"] = content_export_json(content_share.content_export, user, session)
      if content_share.content_export.context_type == "Course"
        json["source_course"] = {
          id: content_share.content_export.context.id,
          name: content_share.content_export.context.nickname_for(user)
        }
      end
    end
    json
  end

  def preload_content_exports(content_shares, additional_associations)
    ActiveRecord::Associations.preload(content_shares, [
                                         { content_export: %i[
                                           context
                                           job_progress
                                           attachment
                                         ] },
                                         *additional_associations
                                       ])
  end

  def sent_content_shares_json(content_shares, user, session, opts = {})
    preload_content_exports(content_shares, [:receivers])
    content_shares_json(content_shares, user, session, opts)
  end

  def received_content_shares_json(content_shares, user, session, opts = {})
    preload_content_exports(content_shares, [:sender])
    content_shares_json(content_shares, user, session, opts)
  end

  def content_shares_json(content_shares, user, session, opts = {})
    content_shares.map do |content_share|
      content_share_json(content_share, user, session, opts)
    end
  end

  private

  def get_content_type_from_export_settings(settings)
    return nil unless settings.key?("selected_content")

    selected_types = settings["selected_content"].keys.filter_map { |k| EXPORT_TYPES[k] }
    %w[module module_item].each { |k| return k if selected_types.include?(k) }
    # otherwise there should be only one selected type...
    selected_types.first
  end
end
