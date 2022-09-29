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
import {defaultCriteria, fillAssessment, getSavedComments, updateAssociationData} from '../helpers'
import {assessments, rubrics} from './fixtures'

describe('defaultCriteria', () => {
  it('only has an id and valid / blank points', () => {
    expect(defaultCriteria('id')).toEqual({
      criterion_id: 'id',
      points: {text: '', valid: true},
    })
  })
})

describe('fillAssessment', () => {
  it('fills out a totally blank assessment', () => {
    expect(fillAssessment(rubrics.points, {})).toEqual({
      score: 0,
      data: [defaultCriteria('_1384'), defaultCriteria('7_391')],
    })
  })

  it('sets editComments to true for all comments existing when the rubric opens', () => {
    const a = assessments.server.points
    const oneComment = {
      ...a,
      data: [a.data[0], {...a.data[1], comments: ''}],
    }
    const filled = fillAssessment(rubrics.points, oneComment)
    expect(filled.data.map(({editComments}) => editComments)).toEqual([true, false])
  })

  it('converts points to editable form for extant assessment', () => {
    const assessment = fillAssessment(rubrics.points, assessments.server.points)
    expect(assessment.data.map(({points}) => points)).toEqual([
      {text: null, valid: true, value: 3.2},
      {text: null, valid: true, value: 3},
    ])
  })

  it('fills in missing values and marks incorrect ones', () => {
    const {data} = assessments.server.points
    const updated = {
      data: [{...data[0], points: null}],
    }
    const assessment = fillAssessment(rubrics.points, updated)
    expect(assessment.data.map(({points}) => points)).toEqual([
      {text: '--', valid: false, value: null},
      {text: '', valid: true},
    ])
  })
})

describe('updateAssociationData', () => {
  it('updates saved comments', () => {
    const assessment = {
      score: 0,
      data: [
        {
          ...defaultCriteria('_1384'),
          comments: 'for later',
          saveCommentsForLater: true,
        },
        defaultCriteria('7_391'),
      ],
    }

    const association = {}
    expect(getSavedComments(association, '_1384')).toBeUndefined()
    updateAssociationData(association, assessment)
    expect(getSavedComments(association, '_1384')).toEqual(['for later'])
  })
})
