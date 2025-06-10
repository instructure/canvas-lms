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

class OutcomeRollup < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  resolves_root_account through: :course
  belongs_to :course
  belongs_to :user
  belongs_to :outcome, class_name: "LearningOutcome"

  validates :calculation_method, presence: true, inclusion: { in: OutcomeCalculationMethod::CALCULATION_METHODS }
  validates :aggregate_score, presence: true
  validates :last_calculated_at, presence: true
  validates :workflow_state, presence: true, inclusion: { in: %w[active deleted] }
end
