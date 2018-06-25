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
import * as GradesApi from 'jsx/assignments/GradeSummary/grades/GradesApi'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

/* eslint-disable qunit/no-identical-names */

QUnit.module('GradeSummary GradeActions', suiteHooks => {
  let store
  let storeEnv

  suiteHooks.beforeEach(() => {
    storeEnv = {
      assignment: {
        courseId: '1201',
        finalGraderId: '1105',
        id: '2301',
        title: 'Example Assignment'
      },
      currentUser: {
        canViewStudentIdentities: false,
        canViewGraderIdentities: true,
        graderId: 'teach',
        id: '1105'
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}]
    }
  })

  function wrapPromise() {
    let rejectPromise
    let resolvePromise

    let promise = new Promise((resolve, reject) => {
      resolvePromise = resolve
      rejectPromise = reject
    })

    const wrappedPromise = {
      then(callback) {
        promise = promise.then(callback)
        return wrappedPromise
      },

      catch(callback) {
        promise = promise.catch(callback)
        return wrappedPromise
      },

      resolve(...args) {
        resolvePromise(...args)
        return promise
      },

      reject(...args) {
        rejectPromise(...args)
        return promise
      }
    }

    return wrappedPromise
  }

  QUnit.module('.addProvisionalGrades()', () => {
    test('adds provisional grades to the store', () => {
      store = configureStore(storeEnv)
      const provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111'
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 9,
          selected: false,
          studentId: '1112'
        }
      ]
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      const grades = store.getState().grades.provisionalGrades
      deepEqual(grades[1112][1102], provisionalGrades[1])
    })
  })

  QUnit.module('.selectFinalGrade()', methodHooks => {
    let provisionalGrades
    let selectProvisionalGradePromise

    methodHooks.beforeEach(() => {
      selectProvisionalGradePromise = wrapPromise()

      sinon.stub(GradesApi, 'selectProvisionalGrade').returns(selectProvisionalGradePromise)

      provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111'
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 9,
          selected: false,
          studentId: '1111'
        }
      ]
    })

    methodHooks.afterEach(() => {
      GradesApi.selectProvisionalGrade.restore()
    })

    QUnit.module('when the grade is an existing, unselected provisional grade', () => {
      function selectProvisionalGrade() {
        store = configureStore(storeEnv)
        store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
        store.dispatch(GradeActions.selectFinalGrade(provisionalGrades[0]))
      }

      test('sets the "set selected provisional grade" status to "started"', () => {
        selectProvisionalGrade()
        const {selectProvisionalGradeStatuses} = store.getState().grades
        equal(selectProvisionalGradeStatuses[1111], GradeActions.STARTED)
      })

      test('selects the provisional grade through the api', () => {
        selectProvisionalGrade()
        strictEqual(GradesApi.selectProvisionalGrade.callCount, 1)
      })

      test('includes the course id when selecting through the api', () => {
        selectProvisionalGrade()
        const [courseId] = GradesApi.selectProvisionalGrade.lastCall.args
        strictEqual(courseId, '1201')
      })

      test('includes the assignment id when selecting through the api', () => {
        selectProvisionalGrade()
        const [, assignmentId] = GradesApi.selectProvisionalGrade.lastCall.args
        strictEqual(assignmentId, '2301')
      })

      test('includes the provisional grade id when selecting through the api', () => {
        selectProvisionalGrade()
        const [, , provisionalGradeId] = GradesApi.selectProvisionalGrade.lastCall.args
        strictEqual(provisionalGradeId, '4601')
      })

      test('updates the selected provisional grade in the store when the request succeeds', async () => {
        selectProvisionalGrade()
        await selectProvisionalGradePromise.resolve()
        const grades = store.getState().grades.provisionalGrades
        strictEqual(grades[1111][1101].selected, true)
      })

      test('sets the "set selected provisional grade" status to "success" when the request succeeds', async () => {
        selectProvisionalGrade()
        await selectProvisionalGradePromise.resolve()
        const {selectProvisionalGradeStatuses} = store.getState().grades
        equal(selectProvisionalGradeStatuses[1111], GradeActions.SUCCESS)
      })

      test('sets the "set selected provisional grade" status to "failure" when a failure occurs', async () => {
        selectProvisionalGrade()
        await selectProvisionalGradePromise.reject(new Error('server error'))
        const {selectProvisionalGradeStatuses} = store.getState().grades
        equal(selectProvisionalGradeStatuses[1111], GradeActions.FAILURE)
      })
    })

    QUnit.module('when the grade is a new custom grade', contextHooks => {
      let gradeInfo
      let updateProvisionalGradePromise

      contextHooks.beforeEach(() => {
        updateProvisionalGradePromise = wrapPromise()

        gradeInfo = {
          grade: 'B',
          graderId: '1105',
          score: 9,
          selected: false,
          studentId: '1111'
        }

        sinon.stub(GradesApi, 'updateProvisionalGrade').returns(updateProvisionalGradePromise)
      })

      contextHooks.afterEach(() => {
        GradesApi.updateProvisionalGrade.restore()
      })

      function selectFinalGrade() {
        store = configureStore(storeEnv)
        store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
        store.dispatch(GradeActions.selectFinalGrade(gradeInfo))
      }

      test('sets the "update grade" status to "started"', () => {
        selectFinalGrade()
        const {updateGradeStatuses} = store.getState().grades
        const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
        equal(statusInfo.status, GradeActions.STARTED)
      })

      test('updates the grade through the api', () => {
        selectFinalGrade()
        strictEqual(GradesApi.updateProvisionalGrade.callCount, 1)
      })

      test('includes the course id when updating the grade through the api', () => {
        selectFinalGrade()
        const [courseId] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(courseId, '1201')
      })

      test('includes the assignmentid when updating the grade through the api', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.assignmentId, '2301')
      })

      test('sets "final" to true when the user is the final grader', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.final, true)
      })

      test('sets "final" to false when the user is not the final grader', () => {
        storeEnv.assignment.finalGraderId = '1101'
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.final, false)
      })

      test('sets the grade as the score when updating the grade through the api', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.grade, 9)
      })

      test('sets "gradedAnonymously" to true when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.gradedAnonymously, true)
      })

      test('sets "gradedAnonymously" to false when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.gradedAnonymously, false)
      })

      test('sets "anonymousId" to the student id when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.anonymousId, '1111')
      })

      test('does not set "userId" when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        notOk('userId' in submission)
      })

      test('sets "userId" to false when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.userId, '1111')
      })

      test('does not set "anonymousId" when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        notOk('anonymousId' in submission)
      })

      QUnit.module('when updating the grade is successful', () => {
        async function selectAndResolve() {
          selectFinalGrade()
          await updateProvisionalGradePromise.resolve({
            grade: 'B',
            provisionalGradeId: '4603',
            score: 9
          })
        }

        test('updates the grade in the store', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          ok(grades[1111][1105])
        })

        test('includes the grade from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          equal(grades[1111][1105].grade, 'B')
        })

        test('includes the graderId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].graderId, '1105')
        })

        test('sets the graderId to the current user graderId when not present on the grade info', async () => {
          delete gradeInfo.graderId
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111].teach.graderId, 'teach')
        })

        test('includes the score from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].score, 9)
        })

        test('includes the studentId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].studentId, '1111')
        })

        test('includes the provisionalGradeId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].id, '4603')
        })

        test('sets the "update grade" status to "success"', async () => {
          await selectAndResolve()
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          equal(statusInfo.status, GradeActions.SUCCESS)
        })

        test('selects the provisional grade through the api', async () => {
          await selectAndResolve()
          strictEqual(GradesApi.selectProvisionalGrade.callCount, 1)
        })
      })

      QUnit.module('when updating the grade fails', () => {
        async function selectAndReject() {
          selectFinalGrade()
          await updateProvisionalGradePromise.reject()
        }

        test('does not update the grade in the store', async () => {
          await selectAndReject()
          const grades = store.getState().grades.provisionalGrades
          notOk(grades[1111][1105])
        })

        test('sets the "update grade" status to "failues"', async () => {
          await selectAndReject()
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          equal(statusInfo.status, GradeActions.FAILURE)
        })

        test('does not select the provisional grade through the api', async () => {
          await selectAndReject()
          strictEqual(GradesApi.selectProvisionalGrade.callCount, 0)
        })
      })

      QUnit.module('when selecting the updated grade', () => {
        async function selectAndResolve() {
          selectFinalGrade()
          await updateProvisionalGradePromise.resolve({
            grade: 'B',
            provisionalGradeId: '4603',
            score: 9
          })
        }

        test('includes the course id when selecting through the api', async () => {
          await selectAndResolve()
          const [courseId] = GradesApi.selectProvisionalGrade.lastCall.args
          strictEqual(courseId, '1201')
        })

        test('includes the assignment id when selecting through the api', async () => {
          await selectAndResolve()
          const [, assignmentId] = GradesApi.selectProvisionalGrade.lastCall.args
          strictEqual(assignmentId, '2301')
        })

        test('includes the provisional grade id when selecting through the api', async () => {
          await selectAndResolve()
          const [, , provisionalGradeId] = GradesApi.selectProvisionalGrade.lastCall.args
          strictEqual(provisionalGradeId, '4603')
        })

        test('sets the "set selected provisional grade" status to "success" when the request succeeds', async () => {
          await selectAndResolve()
          await selectProvisionalGradePromise.resolve()
          const {selectProvisionalGradeStatuses} = store.getState().grades
          equal(selectProvisionalGradeStatuses[1111], GradeActions.SUCCESS)
        })

        test('sets the "set selected provisional grade" status to "failure" when a failure occurs', async () => {
          await selectAndResolve()
          await selectProvisionalGradePromise.reject(new Error('server error'))
          const {selectProvisionalGradeStatuses} = store.getState().grades
          equal(selectProvisionalGradeStatuses[1111], GradeActions.FAILURE)
        })
      })
    })

    QUnit.module('when the grade is an existing custom grade and is selected', contextHooks => {
      let gradeInfo
      let updateProvisionalGradePromise

      contextHooks.beforeEach(() => {
        updateProvisionalGradePromise = wrapPromise()

        gradeInfo = {
          grade: 'B',
          graderId: '1105',
          id: '4603',
          score: 9,
          selected: true,
          studentId: '1111'
        }

        sinon.stub(GradesApi, 'updateProvisionalGrade').returns(updateProvisionalGradePromise)
      })

      contextHooks.afterEach(() => {
        GradesApi.updateProvisionalGrade.restore()
      })

      function selectFinalGrade() {
        store = configureStore(storeEnv)
        store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
        store.dispatch(GradeActions.selectFinalGrade(gradeInfo))
      }

      test('sets the "update grade" status to "started"', () => {
        selectFinalGrade()
        const {updateGradeStatuses} = store.getState().grades
        const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
        equal(statusInfo.status, GradeActions.STARTED)
      })

      test('updates the grade through the api', () => {
        selectFinalGrade()
        strictEqual(GradesApi.updateProvisionalGrade.callCount, 1)
      })

      test('includes the course id when updating the grade through the api', () => {
        selectFinalGrade()
        const [courseId] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(courseId, '1201')
      })

      test('includes the assignmentid when updating the grade through the api', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.assignmentId, '2301')
      })

      test('sets "final" to true when the user is the final grader', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.final, true)
      })

      test('sets "final" to false when the user is not the final grader', () => {
        storeEnv.assignment.finalGraderId = '1101'
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.final, false)
      })

      test('sets the grade as the score when updating the grade through the api', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.grade, 9)
      })

      test('sets "gradedAnonymously" to true when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.gradedAnonymously, true)
      })

      test('sets "gradedAnonymously" to false when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.gradedAnonymously, false)
      })

      test('sets "anonymousId" to the student id when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.anonymousId, '1111')
      })

      test('does not set "userId" when the user cannot view student identities', () => {
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        notOk('userId' in submission)
      })

      test('sets "userId" to false when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        strictEqual(submission.userId, '1111')
      })

      test('does not set "anonymousId" when the user can view student identities', () => {
        storeEnv.currentUser.canViewStudentIdentities = true
        selectFinalGrade()
        const [, submission] = GradesApi.updateProvisionalGrade.lastCall.args
        notOk('anonymousId' in submission)
      })

      QUnit.module('when updating the grade is successful', () => {
        async function selectAndResolve() {
          selectFinalGrade()
          await updateProvisionalGradePromise.resolve({
            grade: 'B',
            provisionalGradeId: '4603',
            score: 9
          })
        }

        test('updates the grade in the store', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          ok(grades[1111][1105])
        })

        test('includes the grade from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          equal(grades[1111][1105].grade, 'B')
        })

        test('includes the graderId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].graderId, '1105')
        })

        test('sets the graderId to the current user graderId when not present on the grade info', async () => {
          delete gradeInfo.graderId
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111].teach.graderId, 'teach')
        })

        test('includes the score from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].score, 9)
        })

        test('includes the studentId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].studentId, '1111')
        })

        test('includes the provisionalGradeId from the given grade info', async () => {
          await selectAndResolve()
          const grades = store.getState().grades.provisionalGrades
          strictEqual(grades[1111][1105].id, '4603')
        })

        test('sets the "update grade" status to "success"', async () => {
          await selectAndResolve()
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          equal(statusInfo.status, GradeActions.SUCCESS)
        })

        test('does not re-select the provisional grade through the api', async () => {
          await selectAndResolve()
          strictEqual(GradesApi.selectProvisionalGrade.callCount, 0)
        })
      })

      QUnit.module('when updating the grade fails', () => {
        async function selectAndReject() {
          selectFinalGrade()
          await updateProvisionalGradePromise.reject()
        }

        test('does not update the grade in the store', async () => {
          await selectAndReject()
          const grades = store.getState().grades.provisionalGrades
          notOk(grades[1111][1105])
        })

        test('sets the "update grade" status to "failues"', async () => {
          await selectAndReject()
          const {updateGradeStatuses} = store.getState().grades
          const statusInfo = updateGradeStatuses.find(info => info.gradeInfo.studentId === '1111')
          equal(statusInfo.status, GradeActions.FAILURE)
        })

        test('does not select the provisional grade through the api', async () => {
          await selectAndReject()
          strictEqual(GradesApi.selectProvisionalGrade.callCount, 0)
        })
      })
    })
  })
})
