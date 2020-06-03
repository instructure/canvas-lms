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

module ConditionalRelease
  class ScoringRangeTemplate < ActiveRecord::Base
    include BoundsValidations
    include Deletion

    belongs_to :rule_template, required: true

    delegate :context_id, :context_type, to: :rule_template

    def build_scoring_range
      ScoringRange.new upper_bound: upper_bound, lower_bound: lower_bound
    end
  end
end
