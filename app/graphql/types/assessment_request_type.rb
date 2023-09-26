# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
  class AssessmentRequestType < ApplicationObjectType
    graphql_name "AssessmentRequest"

    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    field :workflow_state, String, null: false
    field :asset_id, String, null: false
    field :available, Boolean, method: :available?, null: true

    field :user, UserType, null: false
    def user
      load_association(:user)
    end

    field :anonymized_user, UserType, null: true
    def anonymized_user
      load_association(:asset).then do |submission|
        Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
          assignment.anonymous_peer_reviews? ? nil : load_association(:user)
        end
      end
    end

    field :anonymous_id, String, null: true
    def anonymous_id
      load_association(:asset).then do |submission|
        Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
          assignment.anonymous_peer_reviews? ? submission.anonymous_id : nil
        end
      end
    end

    field :asset_submission_type, String, null: true
    def asset_submission_type
      load_association(:asset).then(&:submission_type)
    end
  end
end
