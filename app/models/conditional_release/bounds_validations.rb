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

# Basic bounds validations for classes including :upper_bound and :lower_bound attributes
module ConditionalRelease
  module BoundsValidations
    def self.included(klass)
      super

      klass.validates :lower_bound, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
      klass.validates :upper_bound, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
      klass.validate :lower_bound_less_than_upper_bound
      klass.validate :bound_must_exist
    end

    private

    def lower_bound_less_than_upper_bound
      if lower_bound.is_a?(Numeric) && upper_bound.is_a?(Numeric) && lower_bound > upper_bound
        errors.add(:base, "lower bound must be less than upper bound")
      end
    end

    def bound_must_exist
      errors.add(:base, "one bound must exist") unless lower_bound || upper_bound
    end
  end
end
