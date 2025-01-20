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

module HorizonValidators
  class AssignmentValidator < ActiveModel::Validator
    def validate(record)
      if record.group_category.present?
        record.errors.add(:group_category, "Group category should not exist")
      end
      invalid_types = record.submission_types_array - AbstractAssignment::HORIZON_SUBMISSION_TYPES
      unless invalid_types.empty?
        record.errors.add(:submission_types, "Invalid submission type for Horizon course: #{invalid_types}")
      end
      if record.peer_reviews
        record.errors.add(:peer_reviews, "Peer reviews are disabled")
      end
    end
  end

  class GroupValidator < ActiveModel::Validator
    def validate(record)
      record.errors.add(:groups, "Can not add groups to Horizon course")
    end
  end
end
