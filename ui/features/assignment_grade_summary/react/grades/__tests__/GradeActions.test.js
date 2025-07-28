/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import * as GradeActions from '../GradeActions'
import * as GradesApi from '../GradesApi'
import configureStore from '../../configureStore'

jest.mock('../GradesApi')

describe('GradeSummary GradeActions', () => {
  let store
  let storeEnv

  beforeEach(() => {
    // Initialize store environment
    storeEnv = {
      assignment: {
        courseId: '1201',
        finalGraderId: '1105',
        id: '2301',
        title: 'Example Assignment',
      },
      currentUser: {
        canViewStudentIdentities: false,
        canViewGraderIdentities: true,
        graderId: 'teach',
        id: '1105',
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}],
    }

    // Reset all mocks before each test
    jest.resetAllMocks()

    // Set default mock implementations
    GradesApi.selectProvisionalGrade.mockResolvedValue()
    GradesApi.bulkSelectProvisionalGrades.mockResolvedValue()
    GradesApi.updateProvisionalGrade.mockResolvedValue()
  })

  /**
   * Helper function to create a deferred promise for testing asynchronous actions
   */
  function createDeferred() {
    let resolve, reject
    // eslint-disable-next-line promise/param-names
    const promise = new Promise((res, rej) => {
      resolve = res
      reject = rej
    })
    return {promise, resolve, reject}
  }

  describe('.addProvisionalGrades()', () => {
    test('adds provisional grades to the store', () => {
      store = configureStore(storeEnv)
      const provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111',
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 9,
          selected: false,
          studentId: '1112',
        },
      ]
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      const grades = store.getState().grades.provisionalGrades
      expect(grades['1112']['1102']).toEqual(provisionalGrades[1])
    })
  })

  describe('.acceptGraderGrades()', () => {
    let provisionalGrades
    let selectProvisionalGradeDeferred

    beforeEach(() => {
      selectProvisionalGradeDeferred = createDeferred()

      // Mock the GradesApi.bulkSelectProvisionalGrades method
      GradesApi.bulkSelectProvisionalGrades.mockImplementation(
        () => selectProvisionalGradeDeferred.promise,
      )

      provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 9.5,
          selected: false,
          studentId: '1111',
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 8.5,
          selected: false,
          studentId: '1112',
        },
        {
          grade: 'C',
          graderId: '1101',
          id: '4603',
          score: 7.5,
          selected: false,
          studentId: '1113',
        },
      ]
    })

    /**
     * Helper function to dispatch actions for accepting grader grades
     */
    function acceptGraderGrades() {
      store = configureStore(storeEnv)
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      store.dispatch(GradeActions.acceptGraderGrades('1101'))
    }

    test('sets the "set bulk select provisional grades" status to "started" for the given grader', () => {
      acceptGraderGrades()
      const {bulkSelectProvisionalGradeStatuses} = store.getState().grades
      expect(bulkSelectProvisionalGradeStatuses['1101']).toBe(GradeActions.STARTED)
    })

    test('bulk selects the provisional grades through the api', () => {
      acceptGraderGrades()
      expect(GradesApi.bulkSelectProvisionalGrades).toHaveBeenCalledTimes(1)
    })

    test('includes the course id when selecting through the api', () => {
      acceptGraderGrades()
      const [courseId] = GradesApi.bulkSelectProvisionalGrades.mock.calls[0]
      expect(courseId).toBe('1201')
    })

    test('includes the assignment id when selecting through the api', () => {
      acceptGraderGrades()
      const [, assignmentId] = GradesApi.bulkSelectProvisionalGrades.mock.calls[0]
      expect(assignmentId).toBe('2301')
    })

    test('includes the provisional grade id when selecting through the api', () => {
      acceptGraderGrades()
      const [, , provisionalGradeIds] = GradesApi.bulkSelectProvisionalGrades.mock.calls[0]
      expect(provisionalGradeIds).toEqual(['4601', '4603'])
    })

    test('updates the selected provisional grades in the store when the request succeeds', async () => {
      acceptGraderGrades()
      await selectProvisionalGradeDeferred.resolve()
      const grades = store.getState().grades.provisionalGrades
      expect(grades['1113']['1101'].selected).toBe(true)
    })

    test('sets the "set selected provisional grades" status to "success" when the request succeeds', async () => {
      acceptGraderGrades()
      await selectProvisionalGradeDeferred.resolve()
      const {bulkSelectProvisionalGradeStatuses} = store.getState().grades
      expect(bulkSelectProvisionalGradeStatuses['1101']).toBe(GradeActions.SUCCESS)
    })

    test('sets the "set selected provisional grades" status to "failure" when a failure occurs', async () => {
      acceptGraderGrades()
      await selectProvisionalGradeDeferred.reject(new Error('server error'))
      await new Promise(resolve => setTimeout(resolve, 0))
      const {bulkSelectProvisionalGradeStatuses} = store.getState().grades
      expect(bulkSelectProvisionalGradeStatuses['1101']).toBe(GradeActions.FAILURE)
    })
  })

  describe('.selectFinalGrade()', () => {
    let provisionalGrades
    let selectProvisionalGradeDeferred

    beforeEach(() => {
      selectProvisionalGradeDeferred = createDeferred()

      // Mock the GradesApi.selectProvisionalGrade method
      GradesApi.selectProvisionalGrade.mockImplementation(
        () => selectProvisionalGradeDeferred.promise,
      )

      provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111',
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 9,
          selected: false,
          studentId: '1111',
        },
      ]
    })

    describe('when the grade is an existing, unselected provisional grade', () => {
      /**
       * Helper function to dispatch actions for selecting a final grade
       */
      function selectProvisionalGrade() {
        store = configureStore(storeEnv)
        store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
        store.dispatch(GradeActions.selectFinalGrade(provisionalGrades[0]))
      }

      test('sets the "set selected provisional grade" status to "started"', () => {
        selectProvisionalGrade()
        const {selectProvisionalGradeStatuses} = store.getState().grades
        expect(selectProvisionalGradeStatuses['1111']).toBe(GradeActions.STARTED)
      })

      test('selects the provisional grade through the api', () => {
        selectProvisionalGrade()
        expect(GradesApi.selectProvisionalGrade).toHaveBeenCalledTimes(1)
      })

      test('includes the course id when selecting through the api', () => {
        selectProvisionalGrade()
        const [courseId] = GradesApi.selectProvisionalGrade.mock.calls[0]
        expect(courseId).toBe('1201')
      })

      test('includes the assignment id when selecting through the api', () => {
        selectProvisionalGrade()
        const [, assignmentId] = GradesApi.selectProvisionalGrade.mock.calls[0]
        expect(assignmentId).toBe('2301')
      })

      test('includes the provisional grade id when selecting through the api', () => {
        selectProvisionalGrade()
        const [, , provisionalGradeId] = GradesApi.selectProvisionalGrade.mock.calls[0]
        expect(provisionalGradeId).toBe('4601')
      })

      test('updates the selected provisional grade in the store when the request succeeds', async () => {
        selectProvisionalGrade()
        await selectProvisionalGradeDeferred.resolve()
        const grades = store.getState().grades.provisionalGrades
        expect(grades['1111']['1101'].selected).toBe(true)
      })

      test('sets the "set selected provisional grade" status to "success" when the request succeeds', async () => {
        selectProvisionalGrade()
        await selectProvisionalGradeDeferred.resolve()
        const {selectProvisionalGradeStatuses} = store.getState().grades
        expect(selectProvisionalGradeStatuses['1111']).toBe(GradeActions.SUCCESS)
      })

      test('sets the "set selected provisional grade" status to "failure" when a failure occurs', async () => {
        selectProvisionalGrade()
        await selectProvisionalGradeDeferred.reject(new Error('server error'))
        await new Promise(resolve => setTimeout(resolve, 0))
        const {selectProvisionalGradeStatuses} = store.getState().grades
        expect(selectProvisionalGradeStatuses['1111']).toBe(GradeActions.FAILURE)
      })
    })

    describe('when the grade is a new custom grade', () => {
      let gradeInfo
      let updateProvisionalGradeDeferred

      beforeEach(() => {
        updateProvisionalGradeDeferred = createDeferred()

        gradeInfo = {
          grade: 'B',
          graderId: '1105',
          score: 9,
          selected: false,
          studentId: '1111',
        }

        // Mock the GradesApi.updateProvisionalGrade method
        GradesApi.updateProvisionalGrade.mockImplementation(
          () => updateProvisionalGradeDeferred.promise,
        )
      })

      /**
       * Helper function to dispatch actions for selecting a final grade
       */
      function selectFinalGrade() {
        store = configureStore(storeEnv)
        store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
        store.dispatch(GradeActions.selectFinalGrade(gradeInfo))
      }

      test('sets the "update grade" status to "started"', () => {
        selectFinalGrade()
        const {updateGradeStatuses} = store.getState().grades
        const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
        expect(statusInfo.status).toBe(GradeActions.STARTED)
      })

      test('updates the grade through the api', () => {
        selectFinalGrade()
        expect(GradesApi.updateProvisionalGrade).toHaveBeenCalledTimes(1)
      })

      test('includes the course id when updating the grade through the api', () => {
        selectFinalGrade()
        const [courseId] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(courseId).toBe('1201')
      })

      test('includes the assignment id when updating the grade through the api', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.assignmentId).toBe('2301')
      })

      test('sets "final" to true when the user is the final grader', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.final).toBe(true)
      })

      test('sets "final" to false when the user is not the final grader', () => {
        storeEnv.assignment.finalGraderId = '1101'
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.final).toBe(false)
      })

      test('sets the grade as the score when updating the grade through the api', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.grade).toBe(9)
      })

      test('sets "gradedAnonymously" to true when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.gradedAnonymously).toBe(true)
      })

      test('sets "gradedAnonymously" to false when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.gradedAnonymously).toBe(false)
      })

      test('sets "anonymousId" to the student id when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.anonymousId).toBe('1111')
      })

      test('does not set "userId" when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission).not.toHaveProperty('userId')
      })

      test('sets "userId" to the student id when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission.userId).toBe('1111')
      })

      test('does not set "anonymousId" when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
        expect(submission).not.toHaveProperty('anonymousId')
      })

      describe('when updating the grade is successful', () => {
        /**
         * Helper function to select and resolve the grade update
         */
        async function selectAndResolve() {
          selectFinalGrade()
          await updateProvisionalGradeDeferred.resolve({
            grade: 'B',
            provisionalGradeId: '4603',
            score: 9,
          })
        }

        test('updates the grade in the store', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105']).toBeTruthy()
        })

        test('includes the grade from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105'].grade).toBe('B')
        })

        test('includes the graderId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105'].graderId).toBe('1105')
        })

        test('sets the graderId to the current user graderId when not present on the grade info', async () => {
          delete gradeInfo.graderId
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['teach'].graderId).toBe('teach')
        })

        test('includes the score from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105'].score).toBe(9)
        })

        test('includes the studentId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105'].studentId).toBe('1111')
        })

        test('includes the provisionalGradeId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105'].id).toBe('4603')
        })

        test('sets the "update grade" status to "success"', async () => {
          await selectAndResolve()
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          expect(statusInfo.status).toBe(GradeActions.SUCCESS)
        })

        test.skip('does not re-select the provisional grade through the api', async () => {
          await selectAndResolve()
          expect(GradesApi.selectProvisionalGrade).toHaveBeenCalledTimes(0)
        })
      })

      describe('when updating the grade fails', () => {
        /**
         * Helper function to select and reject the grade update
         */
        async function selectAndReject() {
          selectFinalGrade()
          await updateProvisionalGradeDeferred.reject()
        }

        test('does not update the grade in the store', async () => {
          await selectAndReject()
          const grades = store.getState().grades.provisionalGrades
          expect(grades['1111']['1105']).toBeFalsy()
        })

        test('sets the "update grade" status to "failure"', async () => {
          await selectAndReject()
          await new Promise(resolve => setTimeout(resolve, 0))
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          expect(statusInfo.status).toBe(GradeActions.FAILURE)
        })

        test('does not select the provisional grade through the api', async () => {
          await selectAndReject()
          expect(GradesApi.selectProvisionalGrade).toHaveBeenCalledTimes(0)
        })
      })

      describe('when selecting the updated grade', () => {
        /**
         * Helper function to select and resolve the grade update
         */
        async function selectAndResolve() {
          selectFinalGrade()
          await updateProvisionalGradeDeferred.resolve({
            grade: 'B',
            provisionalGradeId: '4603',
            score: 9,
          })
        }

        test('includes the course id when selecting through the api', async () => {
          await selectAndResolve()
          const [courseId] = GradesApi.selectProvisionalGrade.mock.calls[0]
          expect(courseId).toBe('1201')
        })

        test('includes the assignment id when selecting through the api', async () => {
          await selectAndResolve()
          const [, assignmentId] = GradesApi.selectProvisionalGrade.mock.calls[0]
          expect(assignmentId).toBe('2301')
        })

        test('includes the provisional grade id when selecting through the api', async () => {
          await selectAndResolve()
          const [, , provisionalGradeId] = GradesApi.selectProvisionalGrade.mock.calls[0]
          expect(provisionalGradeId).toBe('4603')
        })

        test('sets the "set selected provisional grade" status to "success" when the request succeeds', async () => {
          await selectAndResolve()
          await selectProvisionalGradeDeferred.resolve()
          const {selectProvisionalGradeStatuses} = store.getState().grades
          expect(selectProvisionalGradeStatuses['1111']).toBe(GradeActions.SUCCESS)
        })

        test('sets the "set selected provisional grade" status to "failure" when a failure occurs', async () => {
          await selectAndResolve()
          await selectProvisionalGradeDeferred.reject(new Error('server error'))
          await new Promise(resolve => setTimeout(resolve, 0))
          const {selectProvisionalGradeStatuses} = store.getState().grades
          expect(selectProvisionalGradeStatuses['1111']).toBe(GradeActions.FAILURE)
        })
      })

      describe('when the grade is an existing custom grade and is selected', () => {
        let gradeInfo
        let updateProvisionalGradeDeferred

        beforeEach(() => {
          updateProvisionalGradeDeferred = createDeferred()

          gradeInfo = {
            grade: 'B',
            graderId: '1105',
            id: '4603',
            score: 9,
            selected: true,
            studentId: '1111',
          }

          // Mock the GradesApi.updateProvisionalGrade method
          GradesApi.updateProvisionalGrade.mockImplementation(
            () => updateProvisionalGradeDeferred.promise,
          )
        })

        /**
         * Helper function to dispatch actions for selecting a final grade
         */
        function selectFinalGrade() {
          store = configureStore(storeEnv)
          store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
          store.dispatch(GradeActions.selectFinalGrade(gradeInfo))
        }

        test('sets the "update grade" status to "started"', () => {
          selectFinalGrade()
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          expect(statusInfo.status).toBe(GradeActions.STARTED)
        })

        test('updates the grade through the api', () => {
          selectFinalGrade()
          expect(GradesApi.updateProvisionalGrade).toHaveBeenCalledTimes(1)
        })

        test('includes the course id when updating the grade through the api', () => {
          selectFinalGrade()
          const [courseId] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(courseId).toBe('1201')
        })

        test('includes the assignment id when updating the grade through the api', () => {
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.assignmentId).toBe('2301')
        })

        test('sets "final" to true when the user is the final grader', () => {
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.final).toBe(true)
        })

        test('sets "final" to false when the user is not the final grader', () => {
          storeEnv.assignment.finalGraderId = '1101'
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.final).toBe(false)
        })

        test('sets the grade as the score when updating the grade through the api', () => {
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.grade).toBe(9)
        })

        test('sets "gradedAnonymously" to true when the user cannot view student identities', () => {
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.gradedAnonymously).toBe(true)
        })

        test('sets "gradedAnonymously" to false when the user can view student identities', () => {
          storeEnv.currentUser.canViewStudentIdentities = true
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.gradedAnonymously).toBe(false)
        })

        test('sets "anonymousId" to the student id when the user cannot view student identities', () => {
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.anonymousId).toBe('1111')
        })

        test('does not set "userId" when the user cannot view student identities', () => {
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission).not.toHaveProperty('userId')
        })

        test('sets "userId" to the student id when the user can view student identities', () => {
          storeEnv.currentUser.canViewStudentIdentities = true
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission.userId).toBe('1111')
        })

        test('does not set "anonymousId" when the user can view student identities', () => {
          storeEnv.currentUser.canViewStudentIdentities = true
          selectFinalGrade()
          const [, submission] = GradesApi.updateProvisionalGrade.mock.calls[0]
          expect(submission).not.toHaveProperty('anonymousId')
        })

        describe('when updating the grade is successful', () => {
          /**
           * Helper function to select and resolve the grade update
           */
          async function selectAndResolve() {
            selectFinalGrade()
            await updateProvisionalGradeDeferred.resolve({
              grade: 'B',
              provisionalGradeId: '4603',
              score: 9,
            })
          }

          test('updates the grade in the store', async () => {
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105']).toBeTruthy()
          })

          test('includes the grade from the given grade info', async () => {
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105'].grade).toBe('B')
          })

          test('includes the graderId from the given grade info', async () => {
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105'].graderId).toBe('1105')
          })

          test('sets the graderId to the current user graderId when not present on the grade info', async () => {
            delete gradeInfo.graderId
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['teach'].graderId).toBe('teach')
          })

          test('includes the score from the given grade info', async () => {
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105'].score).toBe(9)
          })

          test('includes the studentId from the given grade info', async () => {
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105'].studentId).toBe('1111')
          })

          test('includes the provisionalGradeId from the given grade info', async () => {
            await selectAndResolve()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105'].id).toBe('4603')
          })

          test('sets the "update grade" status to "success"', async () => {
            await selectAndResolve()
            const {updateGradeStatuses} = store.getState().grades
            const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
            expect(statusInfo.status).toBe(GradeActions.SUCCESS)
          })

          test('does not re-select the provisional grade through the api', async () => {
            await selectAndResolve()
            expect(GradesApi.selectProvisionalGrade).toHaveBeenCalledTimes(0)
          })
        })

        describe('when updating the grade fails', () => {
          /**
           * Helper function to select and reject the grade update
           */
          async function selectAndReject() {
            selectFinalGrade()
            await updateProvisionalGradeDeferred.reject()
          }

          test('does not update the grade in the store', async () => {
            await selectAndReject()
            const grades = store.getState().grades.provisionalGrades
            expect(grades['1111']['1105']).toBeFalsy()
          })

          test('sets the "update grade" status to "failure"', async () => {
            await selectAndReject()
            await new Promise(resolve => setTimeout(resolve, 0))
            const {updateGradeStatuses} = store.getState().grades
            const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
            expect(statusInfo.status).toBe(GradeActions.FAILURE)
          })

          test('does not select the provisional grade through the api', async () => {
            await selectAndReject()
            expect(GradesApi.selectProvisionalGrade).toHaveBeenCalledTimes(0)
          })
        })
      })
    })
  })
})
