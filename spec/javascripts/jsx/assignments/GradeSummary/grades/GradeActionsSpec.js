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

import * as GradeActions from 'jsx/assignments/GradeSummary/grades/GradeActions'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

QUnit.module('GradeSummary GradeActions', suiteHooks => {
  let store

  suiteHooks.beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        id: '2301',
        title: 'Example Assignment'
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}]
    })
  })

  QUnit.module('.addProvisionalGrades()', () => {
    test('adds provisional grades to the store', () => {
      const provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          studentId: '1111'
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 9,
          studentId: '1112'
        }
      ]
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      const grades = store.getState().grades.provisionalGrades
      deepEqual(grades[1112][1102], provisionalGrades[1])
    })
  })
})
