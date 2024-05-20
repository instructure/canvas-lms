# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Checkpoints::AggregatorService < ApplicationService
  private

  def checkpoint_aggregation_supported?(assignment)
    assignment.present? &&
      assignment.active? &&
      assignment.has_sub_assignments? &&
      !!assignment.root_account&.feature_enabled?(:discussion_checkpoints)
  end

  def sum(objects, field_name)
    values_to_sum = objects.pluck(field_name).compact
    values_to_sum.empty? ? nil : values_to_sum.sum
  end

  def max(objects, field_name)
    objects.pluck(field_name).compact.max
  end
end
