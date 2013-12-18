#
# Copyright (C) 2013 Instructure, Inc.
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

module Api::V1::OutcomeResults
  include Api::V1::Outcome

  # Public: Serializes the rollups produced by Outcomes::ResultAnalytics.
  #
  # rollups - The rollups from Outcomes::ResultAnalytics to seralize
  #
  # Returns a hash that can be converted into json.
  def outcome_results_rollup_json(rollups, outcomes)
    {
      rollups: sanitize_rollups(rollups),
      linked: {
        outcomes: outcomes.map { |o| outcome_json(o, @current_user, session) },
      },
    }
  end

  # Internal: Returns a suitable output hash for the rollups
  def sanitize_rollups(rollups)
    rollups.map do |rollup|
      {
        id: rollup[:user].id,
        name: rollup[:user].name,
        scores: rollup[:scores].map { |score| sanitize_rollup_score(score) },
      }
    end
  end

  # Internal: Returns a suitable output hash for the rollup score
  def sanitize_rollup_score(score)
    {
      outcome_id: score[:outcome].id,
      score: score[:score],
    }
  end

end
