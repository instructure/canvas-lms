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
    # this is uglier than it should be to inject section ids. they really should
    # be in a 'links' section or something.
    # ideally, we would have some seperate mapping from users to course sections
    # it will also need to change is context is ever not a course
    # we're mostly assuming that there is one section enrollment per user. if a user
    # is in multiple sections, they will have multiple rollup results. pagination is
    # still by user, so the counts won't match up. again, this is a very rare thing
    results = []
    rollups.each do |rollup|
      row = {
        id: rollup[:user].id,
        name: rollup[:user].name,
        scores: rollup[:scores].map { |score| sanitize_rollup_score(score) },
      }
      rollup[:user].sections_for_course(@context).each do |section|
        results << row.merge(links: {section: section.id})
      end
    end
    results
  end

  # Internal: Returns a suitable output hash for the rollup score
  def sanitize_rollup_score(score)
    {
      score: score[:score],
      links: {outcome: score[:outcome].id},
    }
  end

end
