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

import _ from 'lodash'
import uuid from 'uuid'
import parseLinkHeader from 'parse-link-header'

const deepMerge = (lhs, rhs) => {
  if (lhs === undefined || lhs === null) {
    return rhs
  } else if (Array.isArray(lhs)) {
    return lhs.concat(rhs)
  } else if (typeof lhs === 'object') {
    return _.mergeWith(lhs, rhs, deepMerge)
  } else {
    return rhs
  }
}

const combine = (promiseOfJson1, promiseOfJson2) => (
  Promise.all([promiseOfJson1, promiseOfJson2])
    .then(([json1, json2]) => deepMerge(json1, json2))
)

const parse = (response) => (
  response.text()
    .then((text) => (JSON.parse(text.replace('while(1);', ''))))
)

export const fetchUrl = (url) => (
  fetch(url, {
    credentials: 'include'
  })
    .then((response) => {
      const linkHeader = response.headers.get('link')
      const next = linkHeader ? parseLinkHeader(linkHeader).next : null
      if (next) {
        return combine(parse(response), fetchUrl(next.url))
      } else {
        return parse(response)
      }
    })
)

const fetchOutcomes = (courseId, studentId) => {
  let outcomeGroups
  let outcomeLinks
  let outcomeRollups
  let outcomeResultsByOutcomeId
  let assignmentsByAssignmentId

  return Promise.all([
    fetchUrl(`/api/v1/courses/${courseId}/outcome_groups?per_page=100`),
    fetchUrl(`/api/v1/courses/${courseId}/outcome_group_links?outcome_style=full&per_page=100`),
    fetchUrl(`/api/v1/courses/${courseId}/outcome_rollups?user_ids[]=${studentId}&per_page=100`)
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
      assignmentsByAssignmentId = _.keyBy(_.flatten(responses.map((response) => response.linked.assignments)), (a) => a.id)
    })
    .then(() => {
      const outcomes = outcomeLinks.map((outcomeLink) => ({
        // outcome ids are not unique (can appear in multiple groups), so we add unique
        // id to manage expansion/contraction
        expansionId: uuid(),
        groupId: outcomeLink.outcome_group.id,
        ...outcomeLink.outcome
      }))

      // filter empty outcome groups
      const outcomesByGroup = _.groupBy(outcomes, (o) => o.groupId)
      outcomeGroups = outcomeGroups.filter((g) => outcomesByGroup[g.id])

      // add rollup scores, mastered
      const outcomesById = _.keyBy(outcomes, (o) => o.id)
      outcomeRollups.rollups[0].scores.forEach((scoreData) => {
        const outcome = outcomesById[scoreData.links.outcome]
        if (outcome) {
          outcome.score = scoreData.score
          outcome.mastered = scoreData.score >= outcome.mastery_points
        }
      })

      // add results, assignments
      outcomes.forEach((outcome) => {
        outcome.results = outcomeResultsByOutcomeId[outcome.id] || [] // eslint-disable-line no-param-reassign
        outcome.results.forEach((result) => {
          result.assignment = assignmentsByAssignmentId[result.links.assignment] // eslint-disable-line no-param-reassign
        })
      })
      return { outcomeGroups, outcomes }
    })
}

export default fetchOutcomes
