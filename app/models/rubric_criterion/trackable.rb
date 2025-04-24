# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class RubricCriterion
  module Trackable
    extend ActiveSupport::Concern

    included do
      before_save :track_metrics
    end

    def track_metrics
      # track that critereon aligned with outcome
      if should_track_criterion_aligned_with_outcome?
        if ignore_for_scoring
          InstStatsd::Statsd.distributed_increment("rubrics_management.rubric_criterion.aligned_with_outcome")
        else
          InstStatsd::Statsd.distributed_increment("rubrics_management.rubric_criterion.aligned_with_outcome_used_for_scoring")
        end
      end
    end

    def should_track_criterion_aligned_with_outcome?
      return true if new_record? && learning_outcome_id.present?
      return true if !new_record? && will_save_change_to_attribute?(:learning_outcome_id) && learning_outcome_id.present?

      false
    end
  end
end
