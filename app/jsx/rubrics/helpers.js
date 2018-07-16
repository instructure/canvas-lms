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

export const defaultCriteria = (id) => ({
  criterion_id: id,
  points: { text: '', valid: true }
})

const fillCriteria = (criterion) => {
  const { points } = criterion
  const hasPoints = !_.isNil(points)
  return {
    ...criterion,
    points: {
      text: hasPoints ? null : '--',
      valid: hasPoints,
      value: points
    }
  }
}

export const fillAssessment = (rubric, partialAssessment) => {
  const prior = _.keyBy(_.cloneDeep(partialAssessment.data), (c) => c.criterion_id)
  return {
    score: 0,
    ...partialAssessment,
    data: rubric.criteria.map((c) =>
      _.has(prior, c.id) ? fillCriteria(prior[c.id]) : defaultCriteria(c.id)
    )
  }
}
