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

class Mutations::DeleteSubmissionDraft < Mutations::BaseMutation
  graphql_name "DeleteSubmissionDraft"

  argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")

  field :submission_draft_ids, [ID], null: true

  def resolve(input:)
    submission = Submission.active.find(input[:submission_id])
    verify_authorized_action!(submission, :submit)

    raise GraphQL::ExecutionError, "no drafts found" if submission.submission_drafts.none?

    context[:submission] = submission
    submission_draft_ids = submission.submission_draft_ids
    submission.delete_submission_drafts!

    { submission_draft_ids: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end

  def self.submission_draft_ids_log_entry(_draft_ids, context)
    # Follow the lead of CreateSubmissionDraft and return the submission object
    # for logging
    context[:submission]
  end
end
