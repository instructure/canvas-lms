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
        record.errors.add(:submission_types, "Invalid submission types for Canvas Career course: #{invalid_types}")
      end

      if record.has_peer_reviews? || record.peer_reviews_assigned
        record.errors.add(:peer_reviews, "Peer reviews are not supported")
      end

      if record.active_rubric_association?
        record.errors.add(:rubric, "Rubric is not supported")
      end

      # invalid if not in a module or only in a published module
      if record.workflow_state == "published" &&
         record.context_module_tags.none? { |t| t.tag_type == "context_module" && t.context_module&.published? }
        record.errors.add(:workflow_state, "Assignment must have a published module")
      end
    end
  end

  class GroupValidator < ActiveModel::Validator
    def validate(record)
      record.errors.add(:groups, "Groups are not supported")
    end
  end

  class DiscussionsValidator < ActiveModel::Validator
    def validate(record)
      unless record.is_announcement
        record.errors.add(:discussion_type, "Discussions are not supported")
      end
    end
  end

  class QuizzesValidator < ActiveModel::Validator
    def validate(record)
      record.errors.add(:quiz_type, "Classic Quizzes are not supported")
    end
  end

  class CollaborationsValidator < ActiveModel::Validator
    def validate(record)
      record.errors.add(:collaborations, "Collaborations are not supported")
    end
  end

  class OutcomesValidator < ActiveModel::Validator
    def validate(record)
      record.errors.add(:outcomes, "Outcomes are not supported")
    end
  end
end
