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
    weighted_average
    standard_decaying_average
    n_mastery
    highest
    latest
    average
  ].freeze

  # TODO: after outcomes_new_decaying_average_calculation feature turned on permanently
  # and data migration we have to change VALID_CALCULATION_INTS for
  # "decaying_average" to (50..99)
  VALID_CALCULATION_INTS = {
    "decaying_average" => (1..99),
    "weighted_average" => (1..99),
    "standard_decaying_average" => (50..99),
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

  before_validation :adjust_calculation_method
  after_save :clear_cached_methods

  def as_json(options = {})
    super(options.reverse_merge(include_root: false, only: %i[id calculation_method calculation_int context_type context_id]))
  end

  def self.find_or_create_default!(context)
    method = OutcomeCalculationMethod.find_by(context:)
    if method&.workflow_state == "active"
      return method
    end

    method ||= OutcomeCalculationMethod.new(context:)
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

  def new_decaying_average_calculation_ff_enabled?
    return context.root_account.feature_enabled?(:outcomes_new_decaying_average_calculation) if context

    LoadAccount.default_domain_root_account.feature_enabled?(:outcomes_new_decaying_average_calculation)
  end

  # We have redefined the calculation methods as follows:
  # weighted_average - This is the preferred way to describe legacy decaying_average.
  # decaying_average - This is the deprecated way to describe legacy decaying_average.
  # standard_decaying_average - This is the preferred way to describe the new decaying_average.
  # if this FF is ENABLED then on user facing side(Only UI)
  # end-user will use "weighted_average" for old "decaying_average"
  # and "decaying_average" for "standard_decaying_average"
  # eg:
  # |User Facing Name | DB Value                                                                           |
  # |------------------------------------------------------------------------------------------------------|
  # |decaying_average | standard_decaying_average [after data migration will be named as decaying_average] |
  # |weighted_average | decaying_average [after data migration this old decaying_average                   |
  # |                 | will be named as weighted_average]                                                 |
  # |------------------------------------------------------------------------------------------------------|
  def adjust_calculation_method(method = calculation_method)
    if new_decaying_average_calculation_ff_enabled?
      self.calculation_method = "decaying_average" if method == "weighted_average"
    elsif method == "standard_decaying_average"
      # If FF is disabled “decaying_average” and “standard_decaying_average”
      # will all be treated the same and calculate using the legacy approach.
      # Any time a learning outcome is updated / saved it will have the calculation_method
      # updated back to being “decaying_average”.
      self.calculation_method = "decaying_average"
    end
  end

  def clear_cached_methods
    if context_type == "Account"
      context.clear_downstream_caches(:resolved_outcome_calculation_method)
    end
  end
end
