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

class Lti::Result < ApplicationRecord
  GRADING_PROGRESS_TYPES = %w[FullyGraded Pending PendingManual Failed NotReady].freeze
  ACCEPT_GIVEN_SCORE_TYPES = %w[FullyGraded PendingManual].freeze
  ACTIVITY_PROGRESS_TYPES = %w[Initialized Started InProgress Submitted Completed].freeze

  self.record_timestamps = false

  validates :line_item, :user, presence: true
  validates :result_maximum, presence: true, unless: proc { |r| r.result_score.blank? }
  validates :result_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :result_maximum, numericality: { greater_than: 0 }, allow_nil: true
  validates :activity_progress,
            inclusion: { in: ACTIVITY_PROGRESS_TYPES },
            allow_nil: true
  validates :grading_progress,
            inclusion: { in: GRADING_PROGRESS_TYPES },
            allow_nil: true

  belongs_to :submission, inverse_of: :lti_result
  belongs_to :user, inverse_of: :lti_results
  belongs_to :line_item, inverse_of: :results, foreign_key: :lti_line_item_id, class_name: 'Lti::LineItem'
end
