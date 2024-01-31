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
import parseLinkHeader from '@canvas/parse-link-header'
import NaiveFetchDispatch from './NaiveFetchDispatch'
import makePromisePool from '@canvas/make-promise-pool'

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

const combine = (promiseOfJson1, promiseOfJson2) =>
  Promise.all([promiseOfJson1, promiseOfJson2]).then(([json1, json2]) => deepMerge(json1, json2))

export function fetchUrl(url, dispatch) {
  return dispatch
    .fetch(url, {
      credentials: 'include',
    })
    .then(response => {
      const linkHeader = response.headers.get('link')
      const next = linkHeader ? parseLinkHeader(linkHeader).next : null
      const jsonPromise = response.json()
      if (next) {
        return combine(jsonPromise, fetchUrl(next.url, dispatch))
      } else {
        return jsonPromise
      }
    })
}

const fetchOutcomes = (courseId, studentId) => {
  const dispatch = new NaiveFetchDispatch()

  let outcomeGroups
  let outcomeLinks
  let outcomeRollups
  let outcomeAssignmentsByOutcomeId
  let outcomeResultsByOutcomeId
  let assignmentsByAssignmentId

  function fetchWithDispatch(url) {
    return fetchUrl(url, dispatch)
  }
  return Promise.all([
    fetchWithDispatch(`/api/v1/courses/${courseId}/outcome_groups?per_page=100`),
    fetchWithDispatch(
      `/api/v1/courses/${courseId}/outcome_group_links?outcome_style=full&per_page=100`
    ),
    fetchWithDispatch(
      `/api/v1/courses/${courseId}/outcome_rollups?user_ids[]=${studentId}&per_page=100`
    ),
    fetchWithDispatch(`/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`),
  ])
    .then(([groups, links, rollups, alignments]) => {
      outcomeGroups = groups
      outcomeLinks = links
      outcomeRollups = rollups
      outcomeAssignmentsByOutcomeId = _.groupBy(alignments, 'learning_outcome_id')
    })
    .then(() => {
      const outcomeIds = outcomeLinks.map(link => link.outcome.id)
      const chunks = _.chunk(outcomeIds, 10)
      return makePromisePool(chunks, chunk => {
        const chunkArgs = chunk.map(id => `outcome_ids[]=${id}`).join('&')
        return fetchWithDispatch(
          `/api/v1/courses/${courseId}/outcome_results?user_ids[]=${studentId}&${chunkArgs}&include[]=assignments&per_page=100`
        )
      })
    })
    .then(({successes, failures}) => {
      if (failures.length > 0) {
        throw new Error('Unable to load all results')
      }
      outcomeResultsByOutcomeId = {}
      assignmentsByAssignmentId = {}
      successes.forEach(({data, res}) => {
        data.forEach(id => {
          outcomeResultsByOutcomeId[id] = outcomeResultsByOutcomeId[id] || []
        })
        res.outcome_results
          .filter(r => !r.hidden)
          .forEach(r => {
            outcomeResultsByOutcomeId[r.links.learning_outcome] ??= []
            outcomeResultsByOutcomeId[r.links.learning_outcome].push(r)
          })
        res.linked.assignments.forEach(a => {
          assignmentsByAssignmentId[a.id] = a
        })
      })
    })
    .then(() => {
      const outcomes = outcomeLinks.map(outcomeLink => ({
        // outcome ids are not unique (can appear in multiple groups), so we add unique
        // id to manage expansion/contraction
        expansionId: uuid(),
        groupId: outcomeLink.outcome_group.id,
        ...outcomeLink.outcome,
      }))

      // filter empty outcome groups
      const outcomesByGroup = _.groupBy(outcomes, o => o.groupId)
      outcomeGroups = outcomeGroups.filter(g => outcomesByGroup[g.id])

      // add rollup scores, mastered
      const outcomesById = _.keyBy(outcomes, o => o.id)
      outcomeRollups.rollups[0].scores.forEach(scoreData => {
        const outcome = outcomesById[scoreData.links.outcome]
        if (outcome) {
          outcome.score = scoreData.score
          outcome.mastered = scoreData.score >= outcome.mastery_points
        }
      })

      // add results, assignments
      outcomes.forEach(outcome => {
        outcome.assignments = outcomeAssignmentsByOutcomeId[outcome.id] || []
        outcome.results = outcomeResultsByOutcomeId[outcome.id] || []
        outcome.results.forEach(result => {
          const key = result.links.assignment || result.links.alignment
          result.assignment = assignmentsByAssignmentId[key]
        })
      })
      return {outcomeGroups, outcomes}
    })
}

export default fetchOutcomes
