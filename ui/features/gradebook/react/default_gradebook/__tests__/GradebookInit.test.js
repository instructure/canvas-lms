/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'

describe('Gradebook init', () => {
  test('correctly loads initial colors', () => {
    const color = '#F3EFEA'
    expect(
      createGradebook({
        colors: {late: color},
      }).options.colors.late
    ).toBe(color)
  })

  test('normalizes the grading period set from the env', () => {
    const options = {
      grading_period_set: {
        id: '1501',
        grading_periods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      },
    }
    const gradingPeriodSet = createGradebook(options).gradingPeriodSet
    expect(gradingPeriodSet.id).toBe('1501')
    expect(gradingPeriodSet.gradingPeriods.length).toBe(2)
    expect(_.map(gradingPeriodSet.gradingPeriods, 'id')).toEqual(['701', '702'])
  })
})

describe('Gradebook#initialize', () => {
  describe('with dataloader stubs', () => {
    let $fixtures

    beforeEach(() => {
      document.body.innerHTML = '<div id="fixtures"></div>'
      $fixtures = document.getElementById('fixtures')
      setFixtureHtml($fixtures)
    })

    afterEach(() => {
      $fixtures.innerHTML = ''
    })

    function createInitializedGradebook(options) {
      const gradebook = createGradebook(options)
      return gradebook
    }

    test('stores the late policy with camelized keys, if one exists', () => {
      const gradebook = createInitializedGradebook({
        late_policy: {late_submission_interval: 'hour'},
      })
      expect(gradebook.courseContent.latePolicy).toEqual({lateSubmissionInterval: 'hour'})
    })

    test('stores the late policy as undefined if the late_policy option is null', () => {
      const gradebook = createInitializedGradebook({late_policy: null})
      expect(gradebook.courseContent.latePolicy).toBeUndefined()
    })
  })
})

describe('Gradebook#initPostGradesLtis', () => {
  test('sets postGradesLtis as an array', () => {
    const gradebook = createGradebook({post_grades_ltis: []})
    expect(gradebook.postGradesLtis).toEqual([])
  })
})
