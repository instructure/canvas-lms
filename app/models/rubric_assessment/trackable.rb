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

class RubricAssessment
  module Trackable
    extend ActiveSupport::Concern

    included do
      before_save :track_metrics
    end

    def track_metrics
      version = rubric.context.feature_enabled?(:enhanced_rubrics) ? :enhanced : :old

      if new_record?
        if assessment_type == "peer_review"
          InstStatsd::Statsd.distributed_increment("grading.rubric.peer_review_assessed_#{version}")
        else
          InstStatsd::Statsd.distributed_increment("grading.rubric.teacher_assessed_#{version}")
        end
      end

      InstStatsd::Statsd.distributed_increment("grading.rubric.teacher_leaves_feedback_#{version}") if should_track_feedback?
    end

    def should_track_feedback?
      return true if new_record? && data_has_a_comment?
      return true if !new_record? && will_save_change_to_attribute?(:data) && data_has_a_comment?

      false
    end

    def data_has_a_comment?
      data&.any? { |assessment| assessment[:comments].present? }
    end
  end
end
