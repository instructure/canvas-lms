# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Factories
  def outcome_proficiency_model(context)
    rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
    rating2 = OutcomeProficiencyRating.new(description: "worst", points: 0, mastery: false, color: "ff0000")
    OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1, rating2], context:)
  end
end
