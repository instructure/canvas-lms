// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute test and/or modify test under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that test will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {NetworkFake} from '@canvas/network/NetworkFake/index'
import store from '../index'

describe('Gradebook > store > fetchFinalGradeOverrides', () => {
  const url = '/courses/0/gradebook/final_grade_overrides'

  let exampleData
  let network

  beforeEach(() => {
    exampleData = {
      finalGradeOverrides: {
        '1': {
          courseGrade: {
            percentage: 88.1,
          },
          gradingPeriodGrades: {
            '2': {
              percentage: 90,
            },
          },
        },
      },
    }
  })

  describe('#fetchFinalGradeOverrides()', () => {
    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
    })

    function resolveRequest() {
      const [request] = getRequests()
      request.response.setJson({
        final_grade_overrides: {
          '1': {
            course_grade: {
              percentage: 88.1,
            },
            grading_period_grades: {
              '2': {
                percentage: 90,
              },
            },
          },
        },
      })
      request.response.send()
    }

    function getRequests() {
      return network.getRequests(request => request.url === url)
    }

    test('sends the request', async () => {
      store.getState().fetchFinalGradeOverrides()
      await network.allRequestsReady()
      const requests = getRequests()
      expect(requests.length).toStrictEqual(1)
    })

    test('saves final grade overrides to the store', async () => {
      const promise = store.getState().fetchFinalGradeOverrides()
      await network.allRequestsReady()
      resolveRequest()
      await promise
      expect(store.getState().finalGradeOverrides).toStrictEqual(exampleData.finalGradeOverrides)
    })
  })
})
