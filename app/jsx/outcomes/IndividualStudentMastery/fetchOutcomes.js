/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'underscore'

const fetchUrl = (url) => (
  fetch(url, {
    credentials: 'include'
  })
    .then((response) => response.text())
    .then((text) => JSON.parse(text.replace('while(1);', '')))
)

const fetchOutcomes = (courseId, studentId) => {
  let outcomeGroups
  let outcomeLinks
  let outcomeRollups
  let outcomeResultsByOutcomeId
  let assignmentsByAssignmentId

  return Promise.all([
    fetchUrl(`/api/v1/courses/${courseId}/outcome_groups`),
    fetchUrl(`/api/v1/courses/${courseId}/outcome_group_links?outcome_style=full`),
    fetchUrl(`/api/v1/courses/${courseId}/outcome_rollups?user_ids[]=${studentId}`)
  ])
    .then(([groups, links, rollups]) => {
      outcomeGroups = groups
      outcomeLinks = links
      outcomeRollups = rollups
    })
    .then(() => (
      Promise.all(outcomeLinks.map((outcomeLink) => (
        fetchUrl(`/api/v1/courses/${courseId}/outcome_results?user_ids[]=${studentId}&outcome_ids[]=${outcomeLink.outcome.id}&include[]=assignments&per_page=100`) // eslint-disable-line max-len
      )))
    ))
    .then((responses) => {
      outcomeResultsByOutcomeId = responses.reduce((acc, response, i) => {
        acc[outcomeLinks[i].outcome.id] = response.outcome_results.filter((r) => !r.hidden);
        return acc
      }, {})
      assignmentsByAssignmentId = _.indexBy(_.flatten(responses.map((response) => response.linked.assignments)), (a) => a.id)
    })
    .then(() => {
      const outcomes = outcomeLinks.map((outcomeLink) => ({ groupId: outcomeLink.outcome_group.id, ...outcomeLink.outcome }))
      const outcomesById = _.indexBy(outcomes, (o) => o.id)

      // add rollup scores, mastered
      outcomeRollups.rollups[0].scores.forEach((scoreData) => {
        const outcome = outcomesById[scoreData.links.outcome]
        outcome.score = scoreData.score
        outcome.mastered = scoreData.score >= outcome.mastery_points
      })
      // add results, assignments
      outcomes.forEach((outcome) => {
        outcome.results = outcomeResultsByOutcomeId[outcome.id] // eslint-disable-line no-param-reassign
        outcome.results.forEach((result) => {
          result.assignment = assignmentsByAssignmentId[result.links.assignment] // eslint-disable-line no-param-reassign
        })
      })
      return { outcomeGroups, outcomes }
    })
}

export default fetchOutcomes
