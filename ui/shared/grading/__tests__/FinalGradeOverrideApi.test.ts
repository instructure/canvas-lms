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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import * as FinalGradeOverrideApi from '../FinalGradeOverrideApi'
import type {FinalGradeOverrideMap} from '../grading.d'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

describe('Gradebook FinalGradeOverrideApi', () => {
  const server = setupServer()

  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('.getFinalGradeOverrides()', () => {
    const url = '/courses/1201/gradebook/final_grade_overrides'

    let responseData: any

    beforeEach(() => {
      responseData = {
        final_grade_overrides: {
          1101: {
            course_grade: {
              percentage: 90.12,
            },
            grading_period_grades: {
              1501: {
                percentage: 81.23,
              },
            },
          },
        },
      }

      server.use(
        http.get(url, () => {
          return HttpResponse.json(responseData)
        }),
      )
    })

    function getFinalGradeOverrides() {
      return FinalGradeOverrideApi.getFinalGradeOverrides('1201')
    }

    it('requests final grade overrides for the course with the given course id', async () => {
      await getFinalGradeOverrides()
      // Request verification is implicit with MSW - if the handler is not matched, the test will fail
    })

    it('camel-cases .finalGradeOverrides in the response data', async () => {
      const data = (await getFinalGradeOverrides()) as {
        finalGradeOverrides: FinalGradeOverrideMap
      }
      expect(Object.keys(data)).toEqual(['finalGradeOverrides'])
    })

    it('camel-cases keys in each student override datum', async () => {
      const {finalGradeOverrides} = (await getFinalGradeOverrides()) as {
        finalGradeOverrides: FinalGradeOverrideMap
      }
      expect(Object.keys(finalGradeOverrides[1101])).toEqual(['courseGrade', 'gradingPeriodGrades'])
    })

    it('ignores an excluded course grade', async () => {
      delete responseData.final_grade_overrides[1101].course_grade
      const {finalGradeOverrides} = (await getFinalGradeOverrides()) as {
        finalGradeOverrides: FinalGradeOverrideMap
      }
      expect(Object.keys(finalGradeOverrides[1101])).toEqual(['gradingPeriodGrades'])
    })

    it('ignores excluded grading period grades', async () => {
      delete responseData.final_grade_overrides[1101].grading_period_grades
      const {finalGradeOverrides} = (await getFinalGradeOverrides()) as {
        finalGradeOverrides: FinalGradeOverrideMap
      }
      expect(Object.keys(finalGradeOverrides[1101])).toEqual(['courseGrade'])
    })

    describe('when the request fails', () => {
      beforeEach(() => {
        server.use(
          http.get(url, () => {
            return HttpResponse.json({error: 'Server Error'}, {status: 500})
          }),
        )
      })

      afterEach(() => {
        jest.clearAllMocks()
      })

      it('shows a flash alert', async () => {
        await getFinalGradeOverrides()
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledTimes(1)
      })

      it('flashes an error', async () => {
        await getFinalGradeOverrides()
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'There was a problem loading final grade overrides.',
          type: 'error',
          err: null,
        })
      })
    })
  })
})
