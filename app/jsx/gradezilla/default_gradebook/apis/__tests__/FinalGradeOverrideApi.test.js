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

import sinon from 'sinon'

import FakeServer from '../../../../__tests__/FakeServer'
import * as FlashAlert from '../../../../shared/FlashAlert'
import * as FinalGradeOverrideApi from '../FinalGradeOverrideApi'

describe('Gradebook FinalGradeOverrideApi', () => {
  let server

  beforeEach(() => {
    server = new FakeServer()
  })

  afterEach(() => {
    server.teardown()
  })

  describe('.getFinalGradeOverrides()', () => {
    const url = '/courses/1201/gradebook/final_grade_overrides'

    let responseData

    beforeEach(() => {
      responseData = {
        final_grade_overrides: {
          1101: {
            course_grade: {
              percentage: 90.12
            },
            grading_period_grades: {
              1501: {
                percentage: 81.23
              }
            }
          }
        }
      }

      server.for(url).respond({status: 200, body: responseData})
    })

    async function getFinalGradeOverrides() {
      return FinalGradeOverrideApi.getFinalGradeOverrides('1201')
    }

    it('requests final grade overrides for the course with the given course id', async () => {
      await getFinalGradeOverrides()
      const requests = server.filterRequests(url)
      expect(requests).toHaveLength(1)
    })

    it('camel-cases .finalGradeOverrides in the response data', async () => {
      const data = await getFinalGradeOverrides()
      expect(Object.keys(data)).toEqual(['finalGradeOverrides'])
    })

    it('camel-cases keys in each student override datum', async () => {
      const {finalGradeOverrides} = await getFinalGradeOverrides()
      expect(Object.keys(finalGradeOverrides[1101])).toEqual(['courseGrade', 'gradingPeriodGrades'])
    })

    it('ignores an excluded course grade', async () => {
      delete responseData.final_grade_overrides[1101].course_grade
      const {finalGradeOverrides} = await getFinalGradeOverrides()
      expect(Object.keys(finalGradeOverrides[1101])).toEqual(['gradingPeriodGrades'])
    })

    it('ignores excluded grading period grades', async () => {
      delete responseData.final_grade_overrides[1101].grading_period_grades
      const {finalGradeOverrides} = await getFinalGradeOverrides()
      expect(Object.keys(finalGradeOverrides[1101])).toEqual(['courseGrade'])
    })

    describe('when the request fails', () => {
      beforeEach(() => {
        server.unsetResponses(url)
        server.for(url).respond({status: 500, body: {error: 'Server Error'}})

        sinon.stub(FlashAlert, 'showFlashAlert')
      })

      afterEach(() => {
        FlashAlert.showFlashAlert.restore()
      })

      it('shows a flash alert', async () => {
        await getFinalGradeOverrides()
        expect(FlashAlert.showFlashAlert.callCount).toBe(1)
      })

      it('flashes an error', async () => {
        await getFinalGradeOverrides()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        expect(type).toBe('error')
      })
    })
  })
})
