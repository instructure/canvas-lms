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

module Types
  class SubmissionDraftType < ApplicationObjectType
    graphql_name "SubmissionDraft"

    implements Interfaces::LegacyIDInterface

    field :active_submission_type, Types::DraftableSubmissionType, null: true

    field :attachments, [Types::FileType], null: true
    def attachments
      load_association(:attachments)
    end

    field :body, String, null: true do
      argument :rewrite_urls, Boolean, required: false
    end

    def body(rewrite_urls: true)
      load_association(:submission).then do |submission|
        Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
          Loaders::AssociationLoader.for(Assignment, :context).load(assignment).then do
            Loaders::ApiContentAttachmentLoader.for(assignment.context).load(object.body).then do |preloaded_attachments|
              GraphQLHelpers::UserContent.process(
                object.body,
                context: assignment.context,
                in_app: context[:in_app],
                request: context[:request],
                preloaded_attachments:,
                user: current_user,
                options: { rewrite_api_urls: rewrite_urls }
              )
            end
          end
        end
      end
    end

    field :external_tool, Types::ExternalToolType, null: true
    def external_tool
      return nil if object.lti_launch_url.blank?

      ContextExternalTool.find_external_tool(
        object.lti_launch_url,
        object.submission.course,
        object.context_external_tool_id
      )
    end

    field :lti_launch_url, Types::UrlType, null: true

    field :meets_media_recording_criteria, Boolean, null: false
    def meets_media_recording_criteria
      object.meets_media_recording_criteria?
    end

    field :meets_text_entry_criteria, Boolean, null: false
    def meets_text_entry_criteria
      object.meets_text_entry_criteria?
    end

    field :meets_upload_criteria, Boolean, null: false
    def meets_upload_criteria
      load_association(:attachments).then do
        object.meets_upload_criteria?
      end
    end

    field :meets_url_criteria, Boolean, null: false
    def meets_url_criteria
      object.meets_url_criteria?
    end

    field :meets_assignment_criteria, Boolean, null: false
    def meets_assignment_criteria
      load_association(:attachments).then do
        load_association(:submission).then do |submission|
          Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do
            object.meets_assignment_criteria?
          end
        end
      end
    end

    field :meets_student_annotation_criteria, Boolean, null: false
    def meets_student_annotation_criteria
      object.meets_student_annotation_criteria?
    end

    field :meets_basic_lti_launch_criteria, Boolean, null: false
    def meets_basic_lti_launch_criteria
      object.meets_basic_lti_launch_criteria?
    end

    field :media_object, Types::MediaObjectType, null: true
    def media_object
      Loaders::MediaObjectLoader.load(object.media_object_id)
    end

    field :resource_link_lookup_uuid, String, null: true

    field :submission_attempt, Integer, null: false

    field :url, Types::UrlType, null: true
  end
end
