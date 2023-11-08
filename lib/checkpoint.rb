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
#

class Checkpoint
  def initialize(assignment)
    @assignment = assignment
  end

  def as_json
    {
      name:,
      label:,
      points_possible:,
      due_at:,
      only_visible_to_overrides:
    }
  end

  private

  def name
    @assignment.name
  end

  def label
    @assignment.checkpoint_label
  end

  def points_possible
    @assignment.points_possible
  end

  def due_at
    @assignment.due_at
  end

  def only_visible_to_overrides
    @assignment.only_visible_to_overrides
  end
end
