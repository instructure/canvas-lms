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
  def outcome_results_rollups_json(rollups)
    {
      rollups: serialize_user_rollups(rollups)
    }
  end

  # Public: Serializes the aggregate rollup. Uses the specified context for the
  # id and name fields.
  def aggregate_outcome_results_rollups_json(rollups)
    {
      rollups: serialize_rollups(rollups, :course)
    }
  end

  # Internal: Returns an Array of serialized rollups.
  def serialize_rollups(rollups, context_key)
    rollups.map { |rollup| serialize_rollup(rollup, context_key) }
  end

  # Internal: Returns a suitable output hash for the rollup.
  def serialize_rollup(rollup, context_key)
    # both Course and User have a name method, so this works for both.
    {
      scores: serialize_rollup_scores(rollup.scores),
      links: {context_key => rollup.context.id.to_s}
    }
  end

  # Internal: Returns a suitable output hash for the user rollups, including
  # section information.
  def serialize_user_rollups(rollups)
    serialized_rollup_pairs = rollups.map do |rollup|
      [rollup, serialize_rollup(rollup, :user)]
    end

    serialized_rollups_with_section_duplicates = serialized_rollup_pairs.map do |rollup, serialized_rollup|
      duplicate_rollup_row_for_sections(rollup, serialized_rollup)
    end

    serialized_rollups_with_section_duplicates.flatten(1)
  end

  # Internal: generates an array of duplicate serialized_rollups with distinct
  # section links for each section of the user's course. If @section is set (as
  # it is if section_id is sent as a parameter to the rollup api endpoint), only
  # that section is included
  def duplicate_rollup_row_for_sections(rollup, serialized_rollup)
    # this is uglier than it should be to inject section ids. they really should
    # be in a 'links' section or something.
    # ideally, we would have some seperate mapping from users to course sections
    # it will also need to change if context is ever not a course
    # we're mostly assuming that there is one section enrollment per user. if a user
    # is in multiple sections, they will have multiple rollup results. pagination is
    # still by user, so the counts won't match up. again, this is a very rare thing
    (@section ? [@section] : rollup.context.sections_for_course(@context)).map do |section|
      serialized_rollup.deep_merge(links: {section: section.id.to_s})
    end
  end

  # Internal: Returns an Array of serialized rollup scores
  def serialize_rollup_scores(scores)
    scores.map { |score| serialize_rollup_score(score) }
  end

  # Internal: Returns a suitable output hash for the rollup score
  def serialize_rollup_score(score)
    {
      score: score.score,
      links: {outcome: score.outcome.id.to_s},
    }
  end
end
