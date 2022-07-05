# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class Mutations::UpdateSubmissionsReadState < Mutations::BaseMutation
  graphql_name "UpdateSubmissionsReadState"

  argument :submission_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Submission")
  argument :read, Boolean, required: true

  field :submissions, [Types::SubmissionType], null: true
  def resolve(input:)
    read_state = input[:read] ? :read : :unread
    submissions = Submission.where(id: input[:submission_ids])
    found_submission_ids = submissions.map { |submission| submission.id.to_s }
    errors = (input[:submission_ids] - found_submission_ids).index_with { "Unable to find Submission" }

    submissions.each do |submission|
      if submission.grants_right?(current_user, :read)
        submission.change_read_state(read_state, current_user)
      else
        errors[submission.id.to_s] = "Not authorized to read Submission"
      end
    end
    submissions = submissions.where.not(id: errors.keys)
    response = {}
    response[:submissions] = submissions if submissions.any?
    response[:errors] = errors if errors.any?
    response
  end
end
