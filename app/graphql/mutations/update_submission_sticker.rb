# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
class Mutations::UpdateSubmissionSticker < Mutations::BaseMutation
  argument :anonymous_id, ID, required: true
  argument :assignment_id, ID, required: true
  argument :sticker, Types::StickerType, required: false

  field :submission, Types::SubmissionType, null: false

  def resolve(input:)
    # Ideally we would use required: :nullable above for sticker, but it doesn't seem to work...
    raise GraphQL::ExecutionError, "'sticker' is required. Provide a value of null to remove a sticker" unless input.key?(:sticker)

    submission = Submission.find_by(
      root_account: context[:domain_root_account],
      assignment_id: input.fetch(:assignment_id),
      anonymous_id: input.fetch(:anonymous_id)
    )

    raise GraphQL::ExecutionError, "not found" if submission.nil? || !submission.grants_right?(current_user, :grade)
    raise GraphQL::ExecutionError, "Stickers feature flag must be enabled" unless submission.course.feature_enabled?(:submission_stickers)

    if submission.update(sticker: input.fetch(:sticker))
      { submission: }
    else
      errors_for(submission)
    end
  end
end
