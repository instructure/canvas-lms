// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
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

import {waitFor} from '@testing-library/react'

import GradeOverride from '@canvas/grading/GradeOverride'
import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'
import FinalGradeOverrides from '../index'

// Mock the external dependencies
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

jest.mock('@canvas/grading/FinalGradeOverrideApi', () => ({
  updateFinalGradeOverride: jest.fn(),
}))

describe('Gradebook FinalGradeOverrides', () => {
  let finalGradeOverrides
  let gradebook
  let grades

  beforeEach(() => {
    const students = {
      1101: {
        enrollments: [{id: '2901', type: 'StudentEnrollment'}],
        id: '1101',
      },
    }

    // `gradebook` is a double because CoffeeScript and AMD cannot be imported
    // into Jest specs
    gradebook = {
      course: {
        id: '1201',
      },

      gradingPeriodId: '1501',

      gradebookGrid: {
        updateRowCell: jest.fn(),
      },

      isFilteringColumnsByGradingPeriod: jest.fn().mockReturnValue(false),

      student(id) {
        return students[id]
      },
    }
    finalGradeOverrides = new FinalGradeOverrides(gradebook)
  })

  describe('#getGradeForUser()', () => {
    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 88.1,
          },

          gradingPeriodGrades: {
            1501: {
              percentage: 91.1,
            },

            1502: {
              percentage: 77.6,
            },
          },
        },
      }
    })

    it('returns the course grade when Gradebook is not filtering to a grading period', () => {
      finalGradeOverrides.setGrades(grades)
      expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(grades[1101].courseGrade)
    })

    it('returns the related grading period grade when Gradebook is filtering to a grading period', () => {
      gradebook.isFilteringColumnsByGradingPeriod.mockReturnValue(true)
      finalGradeOverrides.setGrades(grades)
      expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(
        grades[1101].gradingPeriodGrades[1501],
      )
    })
  })

  describe('#getPendingGradeInfoForUser()', () => {
    it('returns the course grade override info when Gradebook is not filtering to a grading period', () => {
      const gradeInfo = new GradeOverrideInfo()
      finalGradeOverrides._datastore.addPendingGradeInfo('1101', null, gradeInfo)
      expect(finalGradeOverrides.getPendingGradeInfoForUser('1101')).toBe(gradeInfo)
    })

    it('returns the related grading period override info when Gradebook is filtering to a grading period', () => {
      gradebook.isFilteringColumnsByGradingPeriod.mockReturnValue(true)
      const gradeInfo = new GradeOverrideInfo()
      finalGradeOverrides._datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
      expect(finalGradeOverrides.getPendingGradeInfoForUser('1101')).toBe(gradeInfo)
    })
  })

  describe('#setGrades()', () => {
    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 88.1,
          },
        },
        1102: {
          courseGrade: {
            percentage: 91.1,
          },
        },
      }
    })

    it('stores the given final grade overrides in the Gradebook', () => {
      finalGradeOverrides.setGrades(grades)
      expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(grades[1101].courseGrade)
    })

    it('updates row cells for each related student', () => {
      finalGradeOverrides.setGrades(grades)
      expect(gradebook.gradebookGrid.updateRowCell.mock.calls).toHaveLength(2)
    })

    it('includes the user id when updating column cells', () => {
      finalGradeOverrides.setGrades(grades)
      const studentIds = [0, 1].map(
        index => gradebook.gradebookGrid.updateRowCell.mock.calls[index][0],
      )
      expect(studentIds).toEqual(['1101', '1102'])
    })

    it('includes the column id when updating column cells', () => {
      finalGradeOverrides.setGrades(grades)
      const columnIds = [0, 1].map(
        index => gradebook.gradebookGrid.updateRowCell.mock.calls[index][1],
      )
      expect(columnIds).toEqual(['total_grade_override', 'total_grade_override'])
    })

    it('updates row cells after storing final grade overrides', () => {
      gradebook.gradebookGrid.updateRowCell.mockImplementation(() => {
        // final grade overrides will have already been updated by this time
        expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(grades[1101].courseGrade)
      })
      finalGradeOverrides.setGrades(grades)
    })
  })

  describe('#updateGrade()', () => {
    const mockUpdateFinalGradeOverride =
      FinalGradeOverrideApi.updateFinalGradeOverride as jest.MockedFunction<
        typeof FinalGradeOverrideApi.updateFinalGradeOverride
      >
    const mockShowFlashAlert = FlashAlert.showFlashAlert as jest.MockedFunction<
      typeof FlashAlert.showFlashAlert
    >

    beforeEach(() => {
      mockUpdateFinalGradeOverride.mockResolvedValue({percentage: 90.0})
      mockShowFlashAlert.mockImplementation(() => {})
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    async function finished() {
      await waitFor(() => mockShowFlashAlert.mock.calls.length > 0)
    }

    it('updates the grade info via the api when the grade info is valid', async () => {
      const gradeInfo = new GradeOverrideInfo({valid: true})
      finalGradeOverrides.updateGrade('1101', gradeInfo)
      await finished()
      expect(mockUpdateFinalGradeOverride.mock.calls).toHaveLength(1)
    })

    describe('before updating via the api', () => {
      let gradeInfo

      beforeEach(() => {
        gradeInfo = new GradeOverrideInfo({valid: true})
        mockUpdateFinalGradeOverride.mockReturnValue(new Promise(() => {}))
      })

      it('adds the grade info as pending grade info', () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        const pendingGradeInfo = finalGradeOverrides.getPendingGradeInfoForUser('1101')
        expect(pendingGradeInfo).toBe(gradeInfo)
      })

      it('adds the pending grade info for the course grade when not filtering to a grading period', () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        const pendingGradeInfo = finalGradeOverrides._datastore.getPendingGradeInfo('1101', null)
        expect(pendingGradeInfo).toBe(gradeInfo)
      })

      it('adds the pending grade info for the grading period grade when filtering to a grading period', () => {
        gradebook.isFilteringColumnsByGradingPeriod.mockReturnValue(true)
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        const pendingGradeInfo = finalGradeOverrides._datastore.getPendingGradeInfo('1101', '1501')
        expect(pendingGradeInfo).toBe(gradeInfo)
      })

      it('updates the row cell', () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        expect(gradebook.gradebookGrid.updateRowCell.mock.calls).toHaveLength(1)
      })

      it('updates the row cell after adding the pending grade', () => {
        gradebook.gradebookGrid.updateRowCell.mockImplementation(() => {
          const pendingGradeInfo = finalGradeOverrides.getPendingGradeInfoForUser('1101')
          expect(pendingGradeInfo).toBe(gradeInfo)
        })
        finalGradeOverrides.updateGrade('1101', gradeInfo)
      })

      it('includes the user id when updating the row cell', () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        const [userId] =
          gradebook.gradebookGrid.updateRowCell.mock.calls[
            gradebook.gradebookGrid.updateRowCell.mock.calls.length - 1
          ]
        expect(userId).toEqual('1101')
      })

      it('includes the column id when updating the row cell', () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        const [, columnId] =
          gradebook.gradebookGrid.updateRowCell.mock.calls[
            gradebook.gradebookGrid.updateRowCell.mock.calls.length - 1
          ]
        expect(columnId).toEqual('total_grade_override')
      })
    })

    describe('when updating via the api', () => {
      let gradeInfo

      beforeEach(() => {
        gradeInfo = new GradeOverrideInfo({
          grade: new GradeOverride({percentage: 90.0}),
          valid: true,
        })
      })

      it('includes the enrollment id for the current user', async () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        await finished()
        const [enrollmentId] =
          mockUpdateFinalGradeOverride.mock.calls[
            mockUpdateFinalGradeOverride.mock.calls.length - 1
          ]
        expect(enrollmentId).toEqual('2901')
      })

      it('includes the grading period id when filtering to a grading period', async () => {
        gradebook.isFilteringColumnsByGradingPeriod.mockReturnValue(true)
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        await finished()
        const [, gradingPeriodId] =
          mockUpdateFinalGradeOverride.mock.calls[
            mockUpdateFinalGradeOverride.mock.calls.length - 1
          ]
        expect(gradingPeriodId).toEqual('1501')
      })

      it('includes a null grading period id when not filtering to a grading period', async () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        await finished()
        const gradingPeriodId =
          mockUpdateFinalGradeOverride.mock.calls[
            mockUpdateFinalGradeOverride.mock.calls.length - 1
          ][1]
        expect(gradingPeriodId).toBe(null)
      })

      it('includes the grade from the given grade info', async () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        await finished()
        const gradeParam =
          mockUpdateFinalGradeOverride.mock.calls[
            mockUpdateFinalGradeOverride.mock.calls.length - 1
          ][2]
        expect(gradeParam).toBe(gradeInfo.grade)
      })
    })

    describe('when the update is successful', () => {
      let gradeFromApi
      let gradeInfo
      let resolvePromise

      beforeEach(() => {
        gradeInfo = new GradeOverrideInfo({
          grade: new GradeOverride({percentage: 90.0}),
          valid: true,
        })
        // Use a separate instance to mimic a new instance from the API call.
        gradeFromApi = new GradeOverride({percentage: 90.0})

        mockUpdateFinalGradeOverride.mockImplementation(() => {
          return new Promise(resolve => {
            resolvePromise = resolve
          })
        })
      })

      async function requestAndResolve() {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        resolvePromise(gradeFromApi)
        await finished()
      }

      it('removes the pending grade info', async () => {
        await requestAndResolve()
        const pendingGradeInfo = finalGradeOverrides.getPendingGradeInfoForUser('1101')
        expect(pendingGradeInfo).toBe(null)
      })

      it('updates the grade for the given user', async () => {
        await requestAndResolve()
        const updatedGrade = finalGradeOverrides._datastore.getGrade('1101', null)
        expect(updatedGrade).toBe(gradeFromApi)
      })

      it('associates the grade with the grading period when filtering to a grading period', async () => {
        gradebook.isFilteringColumnsByGradingPeriod.mockReturnValue(true)
        await requestAndResolve()
        const updatedGrade = finalGradeOverrides._datastore.getGrade('1101', '1501')
        expect(updatedGrade).toBe(gradeFromApi)
      })

      it('updates the row cell', async () => {
        await requestAndResolve()
        // The second call happens when the request returns successfully.
        expect(gradebook.gradebookGrid.updateRowCell.mock.calls).toHaveLength(2)
      })

      it('updates the row cell after removing the pending grade', async () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        gradebook.gradebookGrid.updateRowCell.mockImplementation(() => {
          const pendingGradeInfo = finalGradeOverrides.getPendingGradeInfoForUser('1101')
          expect(pendingGradeInfo).toBe(null)
        })
        resolvePromise(gradeFromApi)
        await finished()
      })

      it('updates the row cell after updating the user grade', async () => {
        finalGradeOverrides.updateGrade('1101', gradeInfo)
        gradebook.gradebookGrid.updateRowCell.mockImplementation(() => {
          const updatedGrade = finalGradeOverrides._datastore.getGrade('1101', null)
          expect(updatedGrade).toBe(gradeFromApi)
        })
        resolvePromise(gradeFromApi)
        await finished()
      })

      it('includes the user id when updating the row cell', async () => {
        await requestAndResolve()
        const [userId] =
          gradebook.gradebookGrid.updateRowCell.mock.calls[
            gradebook.gradebookGrid.updateRowCell.mock.calls.length - 1
          ]
        expect(userId).toEqual('1101')
      })

      it('includes the column id when updating the row cell', async () => {
        await requestAndResolve()
        const [, columnId] =
          gradebook.gradebookGrid.updateRowCell.mock.calls[
            gradebook.gradebookGrid.updateRowCell.mock.calls.length - 1
          ]
        expect(columnId).toEqual('total_grade_override')
      })

      it('shows a flash alert', async () => {
        await requestAndResolve()
        expect(mockShowFlashAlert.mock.calls).toHaveLength(1)
      })

      it('uses the "success" type for the flash alert', async () => {
        await requestAndResolve()
        const [{type}] = mockShowFlashAlert.mock.calls[mockShowFlashAlert.mock.calls.length - 1]
        expect(type).toEqual('success')
      })
    })

    describe('when the update fails', () => {
      let gradeInfo
      let rejectPromise

      beforeEach(async () => {
        gradeInfo = new GradeOverrideInfo({
          grade: new GradeOverride({percentage: 90.0}),
          valid: true,
        })

        mockUpdateFinalGradeOverride.mockImplementation(() => {
          return new Promise((resolve, reject) => {
            rejectPromise = reject
          })
        })

        finalGradeOverrides.updateGrade('1101', gradeInfo)
        rejectPromise()
        await finished()
      })

      it('shows a flash alert', () => {
        expect(mockShowFlashAlert.mock.calls).toHaveLength(1)
      })

      it('uses the "error" type for the flash alert', () => {
        const [{type}] = mockShowFlashAlert.mock.calls[mockShowFlashAlert.mock.calls.length - 1]
        expect(type).toEqual('error')
      })
    })

    describe('when the given grade info is invalid', () => {
      let gradeInfo

      beforeEach(() => {
        gradeInfo = new GradeOverrideInfo({
          enteredValue: 'invalid',
          valid: false,
        })

        finalGradeOverrides.updateGrade('1101', gradeInfo)
      })

      it('does not update the grade via the api', () => {
        expect(mockUpdateFinalGradeOverride.mock.calls).toHaveLength(0)
      })

      it('shows a flash alert', () => {
        expect(mockShowFlashAlert.mock.calls).toHaveLength(1)
      })

      it('uses the "error" type for the flash alert', () => {
        const [{type}] = mockShowFlashAlert.mock.calls[mockShowFlashAlert.mock.calls.length - 1]
        expect(type).toEqual('error')
      })
    })
  })
})
