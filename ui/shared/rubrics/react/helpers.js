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
import {isNil, has, keyBy, set, get, uniq, cloneDeep} from 'es-toolkit/compat'

export const defaultCriteria = id => ({
  criterion_id: id,
  points: {text: '', valid: true},
})

const fillCriteria = criterion => {
  const {comments, points} = criterion
  const hasPoints = !isNil(points)
  const hasComments = !isNil(comments) && comments.length > 0
  return {
    ...criterion,
    points: {
      text: hasPoints ? null : '--',
      valid: hasPoints,
      value: points,
    },
    editComments: hasComments,
  }
}

export const fillAssessment = (rubric, partialAssessment, assessmentDefaults) => {
  const prior = keyBy(cloneDeep(partialAssessment.data), c => c.criterion_id)

  return {
    score: 0,
    ...assessmentDefaults,
    ...partialAssessment,
    data: rubric.criteria.map(c =>
      has(prior, c.id) ? fillCriteria(prior[c.id]) : defaultCriteria(c.id),
    ),
  }
}

const savedCommentPath = id => ['summary_data', 'saved_comments', id]
export const getSavedComments = (association, id) =>
  get(association, savedCommentPath(id), undefined)

export const updateAssociationData = (association, assessment) => {
  assessment.data
    .filter(({saveCommentsForLater}) => saveCommentsForLater)
    .forEach(({criterion_id: id, comments}) => {
      const prior = getSavedComments(association, id) || []
      set(association, savedCommentPath(id), uniq([...prior, comments]))
    })
}
