# frozen_string_literal: true

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

  CALCULATION_METHODS = %w[
    decaying_average
    n_mastery
    highest
    latest
    average
  ].freeze

  VALID_CALCULATION_INTS = {
    "decaying_average" => (1..99),
    "n_mastery" => (1..10),
    "highest" => [].freeze,
    "latest" => [].freeze,
    "average" => [].freeze,
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
    in: lambda do |model|
      VALID_CALCULATION_INTS[model.calculation_method].presence || [nil] # if valid ints == [], value must be nil
    end,
    if: lambda do |model|
      CALCULATION_METHODS.include?(model.calculation_method)
    end,
    message: -> { t("invalid calculation_int for this calculation_method") }
  }

  after_save :clear_cached_methods

  def as_json(options = {})
    super(options.reverse_merge(include_root: false, only: %i[id calculation_method calculation_int context_type context_id]))
  end

  def self.find_or_create_default!(context)
    method = OutcomeCalculationMethod.find_by(context: context)
    if method&.workflow_state == "active"
      return method
    end

    method ||= OutcomeCalculationMethod.new(context: context)
    method.workflow_state = "active"
    method.calculation_method = "highest"
    method.calculation_int = nil
    GuardRail.activate(:primary) { method.save! }
    method
  rescue ActiveRecord::RecordNotUnique
    retry
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.errors[:context_id] == ["has already been taken"]

    retry
  end

  def clear_cached_methods
    if context_type == "Account"
      context.clear_downstream_caches(:resolved_outcome_calculation_method)
    end
  end
end
