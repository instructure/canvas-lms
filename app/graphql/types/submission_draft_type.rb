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
    graphql_name 'SubmissionDraft'

    implements Interfaces::LegacyIDInterface

    field :attachments, [Types::FileType], null: true
    def attachments
      load_association(:attachments)
    end

    field :body, String, null: true
    def body
      load_association(:submission).then do |submission|
        Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
          Loaders::AssociationLoader.for(Assignment, :context).load(assignment).then do
            Loaders::ApiContentAttachmentLoader.for(assignment.context).load(object.body).then do |preloaded_attachments|
              GraphQLHelpers::UserContent.process(
                object.body,
                context: assignment.context,
                in_app: context[:in_app],
                request: context[:request],
                preloaded_attachments: preloaded_attachments,
                user: current_user
              )
            end
          end
        end
      end
    end

    field :meets_assignment_criteria, Boolean, null: false
    def meets_assignment_criteria
      load_association(:submission).then do |submission|
        Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do
          object.meets_assignment_criteria?
        end
      end
    end

    field :submission_attempt, Integer, null: false

    field :url, Types::UrlType, null: true
  end
end
