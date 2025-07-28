/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {transformRubricData, transformRubricAssessmentData} from '../RubricHelpers'

describe('transformRubricData', () => {
  it('returns the original rubric if it is falsey', () => {
    expect(transformRubricData(undefined)).toBe(undefined)
  })

  it('assigns the rubric _id to id', () => {
    const rubric = transformRubricData({_id: '123'})
    expect(rubric.id).toBe('123')
    expect(rubric._id).toBe(undefined)
  })

  it('assigns the criterion _id to id', () => {
    const criterion = transformRubricData({
      _id: '123',
      criteria: [{_id: '456'}],
    }).criteria[0]

    expect(criterion.id).toBe('456')
    expect(criterion._id).toBe(undefined)
  })

  it('assigns the outcome _id to the criterion learning_outcome_id', () => {
    const criterion = transformRubricData({
      _id: '123',
      criteria: [{_id: '456', outcome: {_id: '789'}}],
    }).criteria[0]

    expect(criterion.learning_outcome_id).toBe('789')
    expect(criterion.outcome).toBe(undefined)
  })

  it('assigns the criterion rating _id to id', () => {
    const criterion = transformRubricData({
      _id: '123',
      criteria: [{_id: '456', ratings: [{_id: '789'}]}],
    }).criteria[0]

    expect(criterion.ratings[0].id).toBe('789')
    expect(criterion.ratings[0]._id).toBe(undefined)
  })
})

describe('transformRubricAssessmentData', () => {
  it('returns the original assessment if it is falsey', () => {
    expect(transformRubricAssessmentData(undefined)).toBe(undefined)
  })

  it('assigns the rating _id to id, but leaves _id in place', () => {
    const rating = transformRubricAssessmentData({
      _id: '123',
      data: [{_id: '456'}],
    }).data[0]
    expect(rating.id).toBe('456')
    expect(rating._id).toBe('456')
  })

  it('assigns the rating criterion_id to null if no criterion exists', () => {
    const rating = transformRubricAssessmentData({
      _id: '123',
      data: [{_id: '456'}],
    }).data[0]
    expect(rating.criterion_id).toBe(null)
  })

  it('assigns the rating criterion _id to criterion_id', () => {
    const rating = transformRubricAssessmentData({
      _id: '123',
      data: [{_id: '456', criterion: {_id: '789'}}],
    }).data[0]
    expect(rating.criterion_id).toBe('789')
    expect(rating.criterion).toBe(undefined)
  })

  it('assigns the rating outcome _id to learning_outcome_id', () => {
    const rating = transformRubricAssessmentData({
      _id: '123',
      data: [{_id: '456', outcome: {_id: '789'}}],
    }).data[0]
    expect(rating.learning_outcome_id).toBe('789')
    expect(rating.outcome).toBe(undefined)
  })
})
