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

module Checkpointable
  def self.included(klass)
    klass.belongs_to :parent_assignment, class_name: "Assignment", optional: true, inverse_of: :checkpoint_assignments
    klass.has_many :checkpoint_assignments, -> { active }, class_name: "Assignment", foreign_key: :parent_assignment_id, inverse_of: :parent_assignment
    klass.has_many :checkpoint_submissions, through: :checkpoint_assignments, source: :submissions

    klass.validates :parent_assignment_id, absence: true, if: :checkpointed?
    klass.validates :parent_assignment_id, comparison: { other_than: :id, message: -> { I18n.t("cannot reference self") } }, allow_nil: true
  end

  def checkpoint?
    parent_assignment_id.present?
  end

  def find_checkpoint(checkpoint_label)
    checkpoint_assignments.find_by(checkpoint_label:)
  end
end
