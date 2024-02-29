# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Loaders::SubmissionVersionNumberLoader < GraphQL::Batch::Loader
  # By default if we pass two submissions with the same id but a different
  # attempt, they will get uniqued into a single submission before they reach
  # the perform method. This breaks submission histories/versionable. Work
  # around this by passing in the submission and submission.attempt to
  # the perform method instead.
  def load(submission)
    super([submission, submission.attempt])
  end

  def perform(submissions_and_attempts)
    Version.preload_version_number(submissions_and_attempts.map(&:first))
    submissions_and_attempts.each do |submission, attempt|
      fulfill([submission, attempt], submission.version_number)
    end
  end
end
