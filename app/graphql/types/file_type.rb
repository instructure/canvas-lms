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
  class FileType < ApplicationObjectType
    include ApplicationHelper

    graphql_name "File"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::ModuleItemInterface
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    # In the application_controller we use this logged_in_user to reflect either the
    # masqueraded user or the actual user. For our purposes since we only want the
    # current user, we can overwrite this here since we don't have access to the OG
    # logged_in_user method.
    def logged_in_user
      @current_user || context[:current_user]
    end

    global_id_field :id

    field :content_type, String, null: true

    field :display_name, String, null: true

    field :mime_class, String, null: true

    field :word_count, Integer, null: true

    field :size, String, null: true
    def size
      ActiveSupport::NumberHelper.number_to_human_size(object.size)
    end

    field :thumbnail_url, Types::UrlType, null: true
    def thumbnail_url
      return if object.locked_for?(current_user, check_policies: true)

      authenticated_thumbnail_url(object)
    end

    field :usage_rights, UsageRightsType, null: true
    delegate :usage_rights, to: :object

    field :url, Types::UrlType, null: true
    def url
      return if object.locked_for?(current_user, check_policies: true)

      opts = {
        download: "1",
        download_frd: "1",
        host: context[:request].host_with_port,
        protocol: context[:request].protocol
      }
      opts[:verifier] = object.uuid if context[:in_app]
      GraphQLHelpers::UrlHelpers.file_download_url(object, opts)
    end

    field :submission_preview_url, Types::UrlType, null: true do
      argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")
    end
    def submission_preview_url(submission_id:)
      return if object.locked_for?(current_user, check_policies: true)

      Loaders::IDLoader.for(Submission).load(submission_id).then do |submission|
        next unless submission.grants_right?(current_user, session, :read)

        # We are checking first to see if the attachment is associated with the given submission id
        # to potentially avoid needing to load submission histories which is expensive.
        if submission.attachment_ids_for_version.include?(object.id)
          load_submission_associations(submission) do |course, assignment|
            get_canvadoc_url(course, assignment, submission)
          end
        else
          load_submission_history_associations(submission) do |course, assignment|
            attachment_ids = submission.submission_history.map(&:attachment_ids_for_version).flatten
            next unless attachment_ids.include?(object.id)

            get_canvadoc_url(course, assignment, submission)
          end
        end
      end
    end

    private

    def load_submission_associations(submission)
      Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
        Loaders::AssociationLoader.for(Assignment, :context).load(assignment).then do |course|
          yield(course, assignment)
        end
      end
    end

    def load_submission_history_associations(submission)
      load_submission_associations(submission) do |course, assignment|
        Loaders::AssociationLoader.for(Submission, :versions).load(submission).then do
          yield(course, assignment)
        end
      end
    end

    def get_canvadoc_url(course, assignment, submission)
      opts = {
        anonymous_instructor_annotations: course.grants_right?(current_user, :manage_grade) && assignment.anonymous_instructor_annotations,
        moderated_grading_allow_list: submission.moderated_grading_allow_list,
        submission_id: submission.id,
        enable_annotations: true,
        enrollment_type: CoursesHelper.user_type(course, current_user)
      }
      object.canvadoc_url(current_user, opts)
    end
  end
end
