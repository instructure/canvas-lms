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

class Checkpoints::AssignmentAggregatorService < Checkpoints::AggregatorService
  AggregateAssignment = Struct.new(:points_possible, :updated_at)

  def initialize(assignment:)
    super()
    @assignment = assignment
  end

  def call
    return false unless checkpoint_aggregation_supported?(@assignment)

    checkpoint_assignments = @assignment.sub_assignments.order(updated_at: :desc).to_a
    return false if checkpoint_assignments.empty?

    aggregate_assignment = build_aggregate_assignment(checkpoint_assignments, @assignment)
    @assignment.update_columns(aggregate_assignment.to_h)
    true
  end

  private

  def build_aggregate_assignment(checkpoint_assignments, parent_assignment)
    assignment = AggregateAssignment.new
    assignment.points_possible = sum(checkpoint_assignments, :points_possible)
    assignment.updated_at = max([*checkpoint_assignments, parent_assignment], :updated_at)
    assignment
  end
end
