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

class Mutations::CreateSubmission < Mutations::BaseMutation
  graphql_name 'CreateSubmission'

  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Assignment')

  field :submission, Types::SubmissionType, null: true

  def resolve(input:)
    assignment = Assignment.active.find(input[:assignment_id])
    assignment = assignment.overridden_for(current_user)
    verify_authorized_action!(assignment, :read)
    verify_authorized_action!(assignment, :submit)

    submission_params = {
      submission_type: 'online_text_entry',
      body: 'Graphql dummy submission text entry'
    }
    submission = assignment.submit_homework(current_user, submission_params)
    {submission: submission}
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  rescue ActiveRecord::RecordInvalid => invalid
    errors_for(invalid.record)
  end
end
