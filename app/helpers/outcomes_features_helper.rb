# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module OutcomesFeaturesHelper
  def account_level_mastery_scales_enabled?(context)
    context&.root_account&.feature_enabled?(:account_level_mastery_scales)
  end

  def improved_outcomes_management_enabled?(context)
    context&.root_account&.feature_enabled?(:improved_outcomes_management)
  end

  def outcome_alignment_summary_with_new_quizzes_enabled?(context)
    context&.feature_enabled?(:outcome_alignment_summary_with_new_quizzes)
  end
end
