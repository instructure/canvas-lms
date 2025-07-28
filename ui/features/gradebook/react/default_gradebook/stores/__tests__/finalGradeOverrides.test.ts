// eslint-disable-next-line @typescript-eslint/ban-ts-comment
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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import store from '../index'

describe('Gradebook > store > fetchFinalGradeOverrides', () => {
  const url = '/courses/0/gradebook/final_grade_overrides'
  const server = setupServer()
  const capturedRequests: any[] = []

  let exampleData

  beforeEach(() => {
    capturedRequests.length = 0
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
    beforeAll(() => {
      server.listen()
    })

    afterEach(() => {
      server.resetHandlers()
    })

    afterAll(() => {
      server.close()
    })

    function getRequests() {
      return capturedRequests.filter(request => request.url.includes('/final_grade_overrides'))
    }

    test('sends the request', async () => {
      server.use(
        http.get(url, async ({request}) => {
          capturedRequests.push({url: request.url})
          return HttpResponse.json({
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
        }),
      )

      await store.getState().fetchFinalGradeOverrides()
      const requests = getRequests()
      expect(requests).toHaveLength(1)
    })

    test('saves final grade overrides to the store', async () => {
      server.use(
        http.get(url, async ({request}) => {
          capturedRequests.push({url: request.url})
          return HttpResponse.json({
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
        }),
      )

      await store.getState().fetchFinalGradeOverrides()
      expect(store.getState().finalGradeOverrides).toStrictEqual(exampleData.finalGradeOverrides)
    })
  })
})
