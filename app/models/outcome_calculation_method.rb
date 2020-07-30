#
# Copyright (C) 2020 - present Instructure, Inc.
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

class OutcomeCalculationMethod < ApplicationRecord
  include Canvas::SoftDeletable
  extend RootAccountResolver

  CALCULATION_METHODS = [
    'decaying_average',
    'n_mastery',
    'highest',
    'latest'
  ].freeze

  VALID_CALCULATION_INTS = {
    "decaying_average" => (1..99),
    "n_mastery" => (1..5),
    "highest" => [].freeze,
    "latest" => [].freeze,
  }.freeze

  belongs_to :context, polymorphic: [:account, :course], required: true
  resolves_root_account through: :context

  validates :context, presence: true
  validates :context_id, uniqueness: { scope: :context_type }
  validates :calculation_method, inclusion: {
    in: CALCULATION_METHODS,
    message: "calculation_method must be one of #{CALCULATION_METHODS}"
  }
  validates :calculation_int, inclusion: {
    in: ->(model) {
      VALID_CALCULATION_INTS[model.calculation_method].presence || [nil] # if valid ints == [], value must be nil
    },
    if: ->(model) {
      CALCULATION_METHODS.include?(model.calculation_method)
    },
    message: "invalid calculation_int for this calculation_method"
  }
end
