//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import {map, find, forEach} from 'lodash'
import ajax from 'ic-ajax'
import startApp from '../start_app'
import Ember, {ObjectProxy} from 'ember'
import fixtures from '../ajax_fixtures'
import {createCourseGradesWithGradingPeriods} from 'spec/jsx/gradebook/GradeCalculatorSpecHelper'
import SRGBController from '../../controllers/screenreader_gradebook_controller'
import userSettings from '@canvas/user-settings'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'
import 'jquery-tinypubsub'
import AsyncHelper from '../AsyncHelper'

function clone(obj) {
  return Ember.copy(obj, true)
}

QUnit.module('ScreenReader Gradebook', suiteHooks => {
  const originalENV = window.ENV
  const qunitTimeout = QUnit.config.testTimeout

  let App = null
  let asyncHelper = null
  let srgb = null

  suiteHooks.beforeEach(() => {
    window.ENV = {}
    QUnit.config.testTimeout = 2000
    fixtures.create()
    sandbox.stub(userSettings, 'contextGet')
    sandbox.stub(userSettings, 'contextSet')
    userSettings.contextGet
      .withArgs('sort_grade_columns_by')
      .returns({sortType: 'assignment_group'})
    userSettings.contextSet.returns({sortType: 'assignment_group'})
    asyncHelper = new AsyncHelper()
    return asyncHelper.start()
  })

  suiteHooks.afterEach(() => {
    asyncHelper.stop()
    Ember.run(App, 'destroy')
    QUnit.config.testTimeout = qunitTimeout
    window.ENV = originalENV
  })

  function initializeApp() {
    App = startApp()
    return Ember.run(() => {
      srgb = SRGBController.create()
      return srgb.set('model', {
        enrollments: Ember.ArrayProxy.create({content: clone(fixtures.students)}),
        assignment_groups: Ember.ArrayProxy.create({content: []}),
        submissions: Ember.ArrayProxy.create({content: []}),
        sections: Ember.ArrayProxy.create({content: clone(fixtures.sections)}),
        outcomes: Ember.ArrayProxy.create({content: clone(fixtures.outcomes)}),
        outcome_rollups: Ember.ArrayProxy.create({content: clone(fixtures.outcome_rollups)}),
      })
    })
  }

  QUnit.module('Controller', hooks => {
    hooks.beforeEach(() => initializeApp())

    test('calculates students properly', () =>
      asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('students.length'), 10)
        equal(srgb.get('students.firstObject').name, fixtures.students[0].user.name)
      }))

    test('calculates assignments properly', () =>
      asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('assignments.length'), 7)
        ok(!srgb.get('assignments').findBy('name', 'Not Graded'))
        equal(
          srgb.get('assignments.firstObject').name,
          fixtures.assignment_groups[0].assignments[0].name
        )
      }))

    test('calculates outcomes properly', () =>
      asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('outcomes.length'), 2)
        equal(srgb.get('outcomes.firstObject').title, fixtures.outcomes[0].title)
      }))

    test('studentsHash returns the expected hash', () =>
      asyncHelper.waitForRequests().then(() => {
        forEach(srgb.studentsHash(), obj => {
          strictEqual(srgb.get('students').findBy('id', obj.id), obj)
        })
      }))

    test('assignmentGroupsHash retuns the expected hash', () =>
      asyncHelper.waitForRequests().then(() => {
        forEach(srgb.assignmentGroupsHash(), obj => {
          strictEqual(srgb.get('assignment_groups').findBy('id', obj.id), obj)
        })
      }))

    test('student objects have isLoaded flag set to true once submissions are loaded', () =>
      asyncHelper.waitForRequests().then(() => {
        srgb.get('students').forEach(s => {
          equal(Ember.get(s, 'isLoaded'), true)
        })
      }))

    test('displayName is hiddenName when hideStudentNames is true', () =>
      asyncHelper.waitForRequests().then(() => {
        srgb.set('hideStudentNames', true)
        equal(srgb.get('displayName'), 'hiddenName')
      }))

    test('displayName is sortable_name when hideStudentNames is false', () =>
      asyncHelper.waitForRequests().then(() => {
        srgb.set('hideStudentNames', false)
        equal(srgb.get('displayName'), 'sortable_name')
      }))

    test('updateSubmission attaches the submission to the student', () =>
      asyncHelper.waitForRequests().then(() => {
        const student = clone(fixtures.students[0].user)
        const submission = clone(fixtures.submissions[student.id].submissions[0])
        srgb.updateSubmission(submission, student)
        strictEqual(student[`assignment_${submission.assignment_id}`], submission)
      }))

    test('studentsInSelectedSection is the same as students when selectedSection is null', () =>
      asyncHelper.waitForRequests().then(() => {
        ok(!srgb.get('selectedSection'))
        deepEqual(srgb.get('students'), srgb.get('studentsInSelectedSection'))
      }))

    test('selectedSubmissionLate is true for a late submission', () =>
      asyncHelper.waitForRequests().then(() => {
        srgb.set('selectedSubmission', {points_deducted: 1})
        ok(srgb.get('selectedSubmissionLate'))
      }))

    test('selectedSubmissionLate is false for an on time submission', () =>
      asyncHelper.waitForRequests().then(() => {
        srgb.set('selectedSubmission', {points_deducted: 0})
        ok(!srgb.get('selectedSubmissionLate'))
      }))

    test('selecting a section filters students properly', () =>
      asyncHelper.waitForRequests().then(() => {
        Ember.run(() => srgb.set('selectedSection', srgb.get('sections.lastObject')))
        equal(srgb.get('studentsInSelectedSection.length'), 6)
        equal(srgb.get('studentsInSelectedSection.firstObject').name, 'Buffy Baker')
      }))

    test('sorting assignments by position', () =>
      asyncHelper.waitForRequests().then(() => {
        Ember.run(() =>
          srgb.set(
            'assignmentSort',
            srgb.get('assignmentSortOptions').findBy('value', 'assignment_group')
          )
        )
        equal(srgb.get('assignments.firstObject.name'), 'Z Eats Soup')
        equal(srgb.get('assignments.lastObject.name'), 'Da Fish and Chips!')
      }))

    test('updates assignment_visibility on an assignment', () =>
      asyncHelper.waitForRequests().then(() => {
        const assignments = srgb.get('assignments')
        const assgn = assignments.objectAt(2)
        srgb.updateAssignmentVisibilities(assgn, '3')
        ok(!assgn.assignment_visibility.contains('3'))
      }))

    test('studentsThatCanSeeAssignment doesnt return all students', () =>
      asyncHelper.waitForRequests().then(() => {
        const assgn = srgb.get('assignments.firstObject')
        const students = srgb.studentsThatCanSeeAssignment(assgn)
        const ids = Object.keys(students)
        equal(ids.length, 1)
        equal(ids[0], '1')
      }))

    test('sorting assignments alphabetically', () =>
      asyncHelper.waitForRequests().then(() => {
        Ember.run(() =>
          srgb.set('assignmentSort', srgb.get('assignmentSortOptions').findBy('value', 'alpha'))
        )
        equal(srgb.get('assignments.firstObject.name'), 'Apples are good')
        equal(srgb.get('assignments.lastObject.name'), 'Z Eats Soup')
      }))

    test('sorting assignments by due date', () =>
      asyncHelper.waitForRequests().then(() => {
        Ember.run(() =>
          srgb.set('assignmentSort', srgb.get('assignmentSortOptions').findBy('value', 'due_date'))
        )
        equal(srgb.get('assignments.firstObject.name'), 'Can You Eat Just One?')
        equal(srgb.get('assignments.lastObject.name'), 'Drink Water')
      }))
  })

  QUnit.module('Loading Submissions', () => {
    QUnit.module('when everything has loaded', contextHooks => {
      contextHooks.beforeEach(() => {
        ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.submissions_url, {
          response: [
            {
              submissions: [
                {
                  assignment_id: '1',
                  assignment_visible: true,
                  cached_due_date: '2015-03-01T12:00:00Z',
                  score: 10,
                  user_id: '1',
                },
                {
                  assignment_id: '2',
                  assignment_visible: true,
                  cached_due_date: '2015-05-02T12:00:00Z',
                  score: 9,
                  user_id: '1',
                },
              ],
              user_id: '01',
            },
            {
              submissions: [
                {
                  assignment_id: '1',
                  assignment_visible: true,
                  cached_due_date: '2015-07-03T12:00:00Z',
                  score: 8,
                  user_id: '2',
                },
              ],
              user_id: '2',
            },
          ],
          jqXHR: {
            getResponseHeader() {
              return {}
            },
          },
          textStatus: 'success',
        })

        ENV.GRADEBOOK_OPTIONS.grading_period_set = {
          id: '1501',
          grading_periods: [
            {
              id: '1403',
              close_date: '2015-07-08T12:00:00Z',
              end_date: '2015-07-01T12:00:00Z',
              is_closed: false,
              start_date: '2015-05-01T12:00:00Z',
            },
            {
              id: '1401',
              close_date: '2015-03-08T12:00:00Z',
              end_date: '2015-03-01T12:00:00Z',
              is_closed: true,
              start_date: '2015-01-01T12:00:00Z',
            },
            {
              id: '1402',
              close_date: '2015-05-08T12:00:00Z',
              end_date: '2015-05-01T12:00:00Z',
              is_closed: false,
              start_date: '2015-03-01T12:00:00Z',
            },
          ],
          weighted: true,
        }

        return initializeApp()
      })

      test('updates effective due dates', () =>
        asyncHelper.waitForRequests().then(() => {
          const effectiveDueDates = srgb.get('effectiveDueDates.content')
          deepEqual(Object.keys(effectiveDueDates), ['1', '2'])
          deepEqual(Object.keys(effectiveDueDates[1]), ['1', '2'])
          deepEqual(Object.keys(effectiveDueDates[2]), ['1'])
        }))

      test('updates effective due dates on related assignments', () =>
        asyncHelper.waitForRequests().then(() => {
          deepEqual(Object.keys(srgb.get('assignments').findBy('id', '1').effectiveDueDates), [
            '1',
            '2',
          ])
          deepEqual(Object.keys(srgb.get('assignments').findBy('id', '2').effectiveDueDates), ['1'])
        }))

      test('updates inClosedGradingPeriod on related assignments', () =>
        asyncHelper.waitForRequests().then(() => {
          strictEqual(srgb.get('assignments').findBy('id', '1').inClosedGradingPeriod, true)
          strictEqual(srgb.get('assignments').findBy('id', '2').inClosedGradingPeriod, false)
        }))
    })

    QUnit.module('when assignment groups load after submissions', contextHooks => {
      let student

      contextHooks.beforeEach(() => {
        initializeApp()
        return asyncHelper.waitForRequests().then(() => {
          student = srgb.get('students.firstObject')

          /*
           * Set all submissions for the student as hidden.
           * This would result in a zero grade for the student.
           */
          let submissions = srgb.submissionsForStudent(student)
          submissions.forEach(submission => {
            srgb.updateSubmission({...submission, hidden: true}, student)
          })
          submissions = srgb.submissionsForStudent(student)

          // Clear the student's current grade.
          Ember.set(student, 'total_grade', null)

          // Simulate the assignments being determined again.
          srgb.set('assignmentsFromGroups.isLoaded', false)
          srgb.set('assignmentsFromGroups.isLoaded', true)
        })
      })

      test('updates the hidden state of submissions', () => {
        const [submission] = srgb.submissionsForStudent(student)
        deepEqual(submission.hidden, false)
      })

      test('recalculates grades for students', () => {
        deepEqual(student.total_grade, {score: 3, possible: 140})
      })
    })
  })

  QUnit.module('#gradesAreWeighted', hooks => {
    let gradingPeriodSet = null

    hooks.beforeEach(() => {
      initializeApp()
      gradingPeriodSet = {
        id: '1501',
        gradingPeriods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      }
    })

    test('is true when the grading period set is weighted', () =>
      asyncHelper.waitForRequests().then(() => {
        gradingPeriodSet.weighted = true
        sinon.stub(srgb, 'getGradingPeriodSet').returns(gradingPeriodSet)
        return Ember.run(() => {
          srgb.set('groupsAreWeighted', false)
          equal(srgb.get('gradesAreWeighted'), true)
        })
      }))

    test('is true when groupsAreWeighted is true', () =>
      asyncHelper.waitForRequests().then(() => {
        gradingPeriodSet.weighted = false
        sinon.stub(srgb, 'getGradingPeriodSet').returns(gradingPeriodSet)
        return Ember.run(() => {
          srgb.set('groupsAreWeighted', true)
          equal(srgb.get('gradesAreWeighted'), true)
        })
      }))

    test('is false when assignment groups are not weighted and the grading period set is not weighted', () =>
      asyncHelper.waitForRequests().then(() => {
        gradingPeriodSet.weighted = false
        sinon.stub(srgb, 'getGradingPeriodSet').returns(gradingPeriodSet)
        return Ember.run(() => {
          srgb.set('groupsAreWeighted', false)
          equal(srgb.get('gradesAreWeighted'), false)
        })
      }))

    test('is false when assignment groups are not weighted and the grading period set is not defined', () =>
      asyncHelper.waitForRequests().then(() => {
        sinon.stub(srgb, 'getGradingPeriodSet').returns(null)
        return Ember.run(() => {
          srgb.set('groupsAreWeighted', false)
          equal(srgb.get('gradesAreWeighted'), false)
        })
      }))
  })

  QUnit.module('#hidePointsPossibleForFinalGrade', hooks => {
    hooks.beforeEach(() => initializeApp())

    test('is true when groupsAreWeighted is true', () =>
      asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          srgb.set('groupsAreWeighted', true)
          equal(srgb.get('hidePointsPossibleForFinalGrade'), true)
        })
      ))

    test('is true when subtotalByGradingPeriod is true', () => {
      sinon.stub(srgb, 'subtotalByGradingPeriod').returns(true)
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          equal(srgb.get('hidePointsPossibleForFinalGrade'), true)
        })
      )
    })

    test('is false when groupsAreWeighted is false and subtotalByGradingPeriod is false', () => {
      sinon.stub(srgb, 'subtotalByGradingPeriod').returns(false)
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          srgb.set('groupsAreWeighted', false)
          equal(srgb.get('hidePointsPossibleForFinalGrade'), false)
        })
      )
    })
  })

  QUnit.module('#getGradingPeriodSet()', hooks => {
    hooks.beforeEach(() => initializeApp())

    test('normalizes the grading period set from the env', () => {
      ENV.GRADEBOOK_OPTIONS.grading_period_set = {
        id: '1501',
        grading_periods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      }
      return asyncHelper.waitForRequests().then(() => {
        const gradingPeriodSet = srgb.getGradingPeriodSet()
        deepEqual(gradingPeriodSet.id, '1501')
        equal(gradingPeriodSet.gradingPeriods.length, 2)
        deepEqual(map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
      })
    })

    test('sets grading period set to null when not defined in the env', () =>
      asyncHelper.waitForRequests().then(() => {
        const gradingPeriodSet = srgb.getGradingPeriodSet()
        deepEqual(gradingPeriodSet, null)
      }))
  })

  QUnit.module('#submissionsForStudent()', hooks => {
    let student = null

    hooks.beforeEach(() => {
      student = {
        id: '1',
        assignment_1: {assignment_id: '1', user_id: '1', name: 'yolo'},
        assignment_2: {assignment_id: '2', user_id: '1', name: 'froyo'},
      }
      ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.submissions_url, {
        response: [
          {
            submissions: [
              {
                assignment_id: '1',
                assignment_visible: true,
                cached_due_date: '2015-03-01T12:00:00Z',
                score: 10,
                user_id: '1',
              },
              {
                assignment_id: '2',
                assignment_visible: true,
                cached_due_date: '2015-05-02T12:00:00Z',
                score: 9,
                user_id: '1',
              },
            ],
            user_id: '1',
          },
          {
            submissions: [
              {
                assignment_id: '1',
                assignment_visible: true,
                cached_due_date: '2015-07-03T12:00:00Z',
                score: 8,
                user_id: '2',
              },
            ],
            user_id: '2',
          },
        ],
        jqXHR: {
          getResponseHeader() {
            return {}
          },
        },
        textStatus: 'success',
      })

      return (ENV.GRADEBOOK_OPTIONS.grading_period_set = {
        id: '1501',
        grading_periods: [
          {
            id: '1403',
            close_date: '2015-07-08T12:00:00Z',
            end_date: '2015-07-01T12:00:00Z',
            is_closed: false,
            start_date: '2015-05-01T12:00:00Z',
          },
          {
            id: '1401',
            close_date: '2015-03-08T12:00:00Z',
            end_date: '2015-03-01T12:00:00Z',
            is_closed: true,
            start_date: '2015-01-01T12:00:00Z',
          },
          {
            id: '1402',
            close_date: '2015-05-08T12:00:00Z',
            end_date: '2015-05-01T12:00:00Z',
            is_closed: false,
            start_date: '2015-03-01T12:00:00Z',
          },
        ],
        weighted: true,
      })
    })

    test('returns all submissions for the student when there are no grading periods', () => {
      ENV.GRADEBOOK_OPTIONS.grading_period_set = null
      initializeApp()
      return asyncHelper.waitForRequests().then(() => {
        Ember.run(() => srgb.set('has_grading_periods', false))
        const submissions = srgb.submissionsForStudent(student)
        propEqual(map(submissions, 'assignment_id'), ['1', '2'])
      })
    })

    test('returns all submissions if "All Grading Periods" is selected', () => {
      initializeApp()
      Ember.run(() => srgb.set('has_grading_periods', true))
      return asyncHelper.waitForRequests().then(() => {
        Ember.run(() => srgb.set('selectedGradingPeriod', {id: '0'}))
        const submissions = srgb.submissionsForStudent(student)
        propEqual(map(submissions, 'assignment_id'), ['1', '2'])
      })
    })

    test('only returns submissions due for the student in the selected grading period', () => {
      initializeApp()
      Ember.run(() => srgb.set('has_grading_periods', true))
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          srgb.set('selectedGradingPeriod', {id: '1401'})
          const submissions = srgb.submissionsForStudent(student)
          propEqual(map(submissions, 'assignment_id'), ['1'])
        })
      )
    })
  })

  QUnit.module('with selected student', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      sinon.stub(srgb, 'calculateStudentGrade')
      sinon.stub(srgb, 'subtotalByGradingPeriod')
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          srgb.set('selectedGradingPeriod', {id: '3', close_date: null})
          srgb.set(
            'assignment_groups',
            Ember.ArrayProxy.create({content: clone(fixtures.assignment_groups)})
          )
          srgb.set('assignment_groups.isLoaded', true)
          const student = srgb.get('students.firstObject')
          return srgb.set('selectedStudent', student)
        })
      )
    })

    test('selectedSubmission is null when only selectedStudent is set', () =>
      asyncHelper.waitForRequests().then(() => {
        strictEqual(srgb.get('selectedSubmission'), null)
      }))
  })

  QUnit.module('with selected student, assignment, and outcome', hooks => {
    let student = null
    let assignment = null

    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          student = srgb.get('students.firstObject')
          assignment = srgb.get('assignments.firstObject')
          const outcome = srgb.get('outcomes.firstObject')
          srgb.set('selectedStudent', student)
          srgb.set('selectedAssignment', assignment)
          srgb.set('selectedOutcome', outcome)
        })
      )
    })

    test('assignmentDetails is computed properly', () =>
      asyncHelper.waitForRequests().then(() => {
        const assignmentDetails = srgb.get('assignmentDetails')
        const selectedAssignment = srgb.get('selectedAssignment')
        strictEqual(assignmentDetails.assignment, selectedAssignment)
        strictEqual(assignmentDetails.cnt, '1')
      }))

    test('outcomeDetails is computed properly', () =>
      asyncHelper.waitForRequests().then(() => {
        const od = srgb.get('outcomeDetails')
        strictEqual(od.cnt, 1)
      }))

    test('selectedSubmission is computed properly', () =>
      asyncHelper.waitForRequests().then(() => {
        const selectedSubmission = srgb.get('selectedSubmission')
        const sub = find(fixtures.submissions, s => s.user_id === student.id)
        const submission = find(sub.submissions, s => s.assignment_id === assignment.id)
        forEach(submission, (val, key) => {
          equal(selectedSubmission[key], val, `${key} is the expected value on selectedSubmission`)
        })
      }))

    test('selectedSubmission sets gradeLocked', () =>
      asyncHelper.waitForRequests().then(() => {
        const selectedSubmission = srgb.get('selectedSubmission')
        equal(selectedSubmission.gradeLocked, false)
      }))

    test('selectedSubmission sets gradeLocked for unassigned students', () =>
      asyncHelper.waitForRequests().then(() => {
        student = srgb.get('students')[1]
        return Ember.run(() => {
          srgb.set('selectedStudent', student)
          const selectedSubmission = srgb.get('selectedSubmission')
          equal(selectedSubmission.gradeLocked, true)
        })
      }))

    test('selectedSubmission displays the proper preview text', () =>
      asyncHelper.waitForRequests().then(() => {
        const selectedSubmission = srgb.get('selectedSubmission')
        const submissionClone = {...selectedSubmission}
        submissionClone.submission_type = null
        return Ember.run(() => {
          srgb.set('selectedSubmission', submissionClone)
          const previewText = srgb.get('submissionPreviewText')
          equal(previewText, 'Has not submitted')
        })
      }))
  })

  QUnit.module('with selected assignment', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() => {
          const assignment = srgb.get('assignments.firstObject')
          return srgb.set('selectedAssignment', assignment)
        })
      )
    })

    test('gets the submission types', () =>
      asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('assignmentSubmissionTypes'), 'None')
        Ember.run(() => {
          const assignments = srgb.get('assignments')
          return srgb.set('selectedAssignment', assignments.objectAt(1))
        })
        equal(srgb.get('assignmentSubmissionTypes'), 'Online URL, Online text entry')
      }))

    test('assignmentInClosedGradingPeriod returns false when the selected assignment is not in a closed grading period', () =>
      asyncHelper.waitForRequests().then(() => {
        Ember.run(() => {
          const assignment = srgb.get('assignments.lastObject')
          assignment.inClosedGradingPeriod = false
          return srgb.set('selectedAssignment', assignment)
        })
        equal(srgb.get('assignmentInClosedGradingPeriod'), false)
      }))

    test('assignmentInClosedGradingPeriod returns true when the selected assignment is in a closed grading period', () =>
      asyncHelper.waitForRequests().then(() => {
        Ember.run(() => {
          const assignment = srgb.get('assignments.lastObject')
          assignment.inClosedGradingPeriod = true
          return srgb.set('selectedAssignment', assignment)
        })
        equal(srgb.get('assignmentInClosedGradingPeriod'), true)
      }))
  })

  QUnit.module('draftState', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper.waitForRequests().then(() =>
        Ember.run(() =>
          srgb.get('assignment_groups').pushObject({
            id: '100',
            name: 'Silent Assignments',
            position: 2,
            assignments: [
              {
                id: '21',
                name: 'Unpublished Assignment',
                points_possible: 10,
                grading_type: 'percent',
                submission_types: ['none'],
                due_at: null,
                position: 6,
                assignment_group_id: '4',
                published: false,
              },
            ],
          })
        )
      )
    })

    test('calculates assignments properly', () =>
      asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('assignments.length'), 7)
        ok(!srgb.get('assignments').findBy('name', 'Unpublished Assignment'))
      }))
  })

  QUnit.module('Grade Calculation', _hooks => {
    const pointedCalculation = {
      assignmentGroups: {},
      final: {
        possible: 100,
        score: 90,
      },
      current: {
        possible: 88,
        score: 70,
      },
    }

    const unpointedCalculation = {
      assignmentGroups: {},
      final: {
        possible: 0,
        score: 0,
      },
      current: {
        possible: 0,
        score: 0,
      },
    }

    function initializeWithCalculation(calculation) {
      App = startApp()
      return Ember.run(() => {
        srgb = SRGBController.create()
        srgb.reopen({
          calculate() {
            return calculation
          },
        })

        return srgb.set('model', {
          enrollments: Ember.ArrayProxy.create({content: clone(fixtures.students)}),
          assignment_groups: Ember.ArrayProxy.create({content: clone(fixtures.assignment_groups)}),
          submissions: Ember.ArrayProxy.create({content: []}),
          sections: Ember.ArrayProxy.create({content: clone(fixtures.sections)}),
        })
      })
    }

    test('calculates final grade with points possible', () => {
      initializeWithCalculation(pointedCalculation)
      return asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('students.firstObject.total_percent'), 79.55)
      })
    })

    test('calculates final grade with no points possible', () => {
      initializeWithCalculation(unpointedCalculation)
      return asyncHelper.waitForRequests().then(() => {
        equal(srgb.get('students.firstObject.total_percent'), 0)
      })
    })
  })

  QUnit.module('#calculate()', hooks => {
    let student = null

    hooks.beforeEach(() => {
      ENV.GRADEBOOK_OPTIONS.grading_period_set = {
        created_at: '2015-07-08T12:00:00Z',
        id: '1501',
        grading_periods: [
          {
            id: '1403',
            close_date: '2015-07-08T12:00:00Z',
            end_date: '2015-07-01T12:00:00Z',
            is_closed: false,
            start_date: '2015-05-01T12:00:00Z',
          },
          {
            id: '1401',
            close_date: '2015-03-08T12:00:00Z',
            end_date: '2015-03-01T12:00:00Z',
            is_closed: true,
            start_date: '2015-01-01T12:00:00Z',
          },
          {
            id: '1402',
            close_date: '2015-05-08T12:00:00Z',
            end_date: '2015-05-01T12:00:00Z',
            is_closed: false,
            start_date: '2015-03-01T12:00:00Z',
          },
        ],
        weighted: true,
      }
      initializeApp()
      return asyncHelper.waitForRequests().then(() => {
        sandbox.stub(CourseGradeCalculator, 'calculate').returns('expected')
        student = srgb.get('students.firstObject')
      })
    })

    test('calculates grades using properties from the gradebook', () => {
      const grades = srgb.calculate(student)
      equal(grades, 'expected')
      const {args} = CourseGradeCalculator.calculate.lastCall
      deepEqual(args[0], srgb.submissionsForStudent(student))
      deepEqual(args[1], srgb.assignmentGroupsHash())
      deepEqual(args[2], srgb.get('weightingScheme'))
      deepEqual(args[4], srgb.getGradingPeriodSet())
    })

    test('scopes effective due dates to the user', () => {
      srgb.calculate(student)
      const dueDates = CourseGradeCalculator.calculate.lastCall.args[5]
      deepEqual(Object.keys(dueDates), ['1', '2', '6']) // assignment ids
    })

    test('calculates grades without grading period data when grading period set is null', () => {
      sinon.stub(srgb, 'getGradingPeriodSet').returns(null)
      srgb.calculate(student)
      const {args} = CourseGradeCalculator.calculate.getCall(0)
      deepEqual(args[0], srgb.submissionsForStudent(student))
      deepEqual(args[1], srgb.assignmentGroupsHash())
      deepEqual(args[2], srgb.get('weightingScheme'))
      equal(typeof args[4], 'undefined')
      equal(typeof args[5], 'undefined')
    })

    test('calculates grades without grading period data when effective due dates are not defined', () => {
      Ember.run(() => srgb.set('effectiveDueDates.content', null))
      srgb.calculate(student)
      const {args} = CourseGradeCalculator.calculate.getCall(0)
      deepEqual(args[0], srgb.submissionsForStudent(student))
      deepEqual(args[1], srgb.assignmentGroupsHash())
      deepEqual(args[2], srgb.get('weightingScheme'))
      equal(typeof args[4], 'undefined')
      equal(typeof args[5], 'undefined')
    })
  })

  QUnit.module('#calculateStudentGrade()', hooks => {
    let exampleGrades = null
    let student = null

    hooks.beforeEach(() => {
      ENV.GRADEBOOK_OPTIONS.grading_period_set = {
        created_at: '2015-07-08T12:00:00Z',
        id: '1501',
        grading_periods: [
          {
            id: '703',
            close_date: '2015-07-08T12:00:00Z',
            end_date: '2015-07-01T12:00:00Z',
            is_closed: false,
            start_date: '2015-05-01T12:00:00Z',
          },
          {
            id: '701',
            close_date: '2015-03-08T12:00:00Z',
            end_date: '2015-03-01T12:00:00Z',
            is_closed: true,
            start_date: '2015-01-01T12:00:00Z',
          },
          {
            id: '702',
            close_date: '2015-05-08T12:00:00Z',
            end_date: '2015-05-01T12:00:00Z',
            is_closed: false,
            start_date: '2015-03-01T12:00:00Z',
          },
        ],
        weighted: true,
      }
      exampleGrades = createCourseGradesWithGradingPeriods()
      initializeApp()
      return asyncHelper.waitForRequests().then(() => {
        sandbox.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
        return (student = srgb.get('students.firstObject'))
      })
    })

    test('stores the current grade on the student when not including ungraded assignments', () => {
      srgb.calculateStudentGrade(student)
      equal(student.total_grade, exampleGrades.current)
    })

    test('stores the final grade on the student when including ungraded assignments', () =>
      Ember.run(() => {
        srgb.set('includeUngradedAssignments', true)
        srgb.calculateStudentGrade(student)
        equal(student.total_grade, exampleGrades.final)
      }))

    test('stores the current grade from the selected grading period when not including ungraded assignments', () => {
      Ember.run(() => {
        srgb.set('includeUngradedAssignments', false)
        return srgb.set('selectedGradingPeriod', {id: '701'})
      })
      return asyncHelper.waitForRequests().then(() => {
        srgb.calculateStudentGrade(student)
        equal(student.total_grade, exampleGrades.gradingPeriods[701].current)
      })
    })

    test('stores the current grade from the selected grading period when not including ungraded assignments (2)', () => {
      Ember.run(() => {
        srgb.set('includeUngradedAssignments', true)
        return srgb.set('selectedGradingPeriod', {id: '701'})
      })
      return asyncHelper.waitForRequests().then(() => {
        srgb.calculateStudentGrade(student)
        equal(student.total_grade, exampleGrades.gradingPeriods[701].final)
      })
    })
  })

  QUnit.module('showNotesColumn', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.custom_column_url = '/here/is/an/:id'
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {id: '42'}
      initializeApp()
      Ember.run(() =>
        srgb.reopen({
          updateOrCreateNotesColumn() {},
        })
      )
      return asyncHelper.waitForRequests()
    })

    test('is true when teacher notes are not hidden', () => {
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {hidden: false}
      equal(srgb.get('showNotesColumn'), true)
    })

    test('is false when teacher notes are hidden', () => {
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {hidden: true}
      equal(srgb.get('showNotesColumn'), false)
    })

    test('is false when teacher notes do not exist', () => {
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = null
      equal(srgb.get('showNotesColumn'), false)
    })
  })

  QUnit.module('shouldCreateNotes', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.custom_column_url = '/here/is/an/:id'
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {id: '42'}
      initializeApp()
      Ember.run(() =>
        srgb.reopen({
          updateOrCreateNotesColumn() {},
        })
      )
      return asyncHelper.waitForRequests()
    })

    test('is false when teacher notes are not hidden', () => {
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {hidden: false}
      return Ember.run(() => {
        srgb.set('showNotesColumn', true)
        equal(srgb.get('shouldCreateNotes'), false)
      })
    })

    test('is false when teacher notes are hidden', () => {
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {hidden: true}
      return Ember.run(() => {
        srgb.set('showNotesColumn', true)
        equal(srgb.get('shouldCreateNotes'), false)
      })
    })

    test('is false when teacher notes do not exist', () => {
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = null
      return Ember.run(() => {
        srgb.set('showNotesColumn', true)
        equal(srgb.get('shouldCreateNotes'), true)
      })
    })
  })

  QUnit.module('notesURL', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.custom_column_url = '/here/is/an/:id'
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = {id: '42'}
      initializeApp()
      Ember.run(() =>
        srgb.reopen({
          updateOrCreateNotesColumn() {},
        })
      )
      return asyncHelper.waitForRequests()
    })

    test('is the "create notes" url when teacher notes do not exist', () => {
      Ember.run(() => srgb.set('shouldCreateNotes', true))
      equal(srgb.get('notesURL'), ENV.GRADEBOOK_OPTIONS.custom_columns_url)
    })

    test('is the "update notes" url when teacher notes exist', () => {
      Ember.run(() => srgb.set('shouldCreateNotes', false))
      equal(srgb.get('notesURL'), '/here/is/an/42', 'computes properly when showing')
    })
  })

  QUnit.module('notesParams', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      Ember.run(() =>
        srgb.reopen({
          updateOrCreateNotesColumn() {},
        })
      )
      return asyncHelper.waitForRequests()
    })

    test('sets hidden to false when the notes column exists and is visible', () =>
      Ember.run(() => {
        srgb.set('showNotesColumn', true)
        srgb.set('shouldCreateNotes', false)
        return deepEqual(srgb.get('notesParams'), {'column[hidden]': false})
      }))

    test('sets hidden to true when the notes column exists and is hidden', () =>
      Ember.run(() => {
        srgb.set('showNotesColumn', false)
        srgb.set('shouldCreateNotes', false)
        return deepEqual(srgb.get('notesParams'), {'column[hidden]': true})
      }))

    test('includes creation parameters when the notes column does not exist', () =>
      Ember.run(() => {
        srgb.set('showNotesColumn', true)
        srgb.set('shouldCreateNotes', true)
        return deepEqual(srgb.get('notesParams'), {
          'column[title]': 'Notes',
          'column[position]': 1,
          'column[teacher_notes]': true,
        })
      }))
  })

  QUnit.module('notesVerb', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      Ember.run(() =>
        srgb.reopen({
          updateOrCreateNotesColumn() {},
        })
      )
      return asyncHelper.waitForRequests()
    })

    test('is POST when the notes column does not exist', () => {
      Ember.run(() => srgb.set('shouldCreateNotes', true))
      equal(srgb.get('notesVerb'), 'POST')
    })

    test('is PUT when the notes column exists', () => {
      Ember.run(() => srgb.set('shouldCreateNotes', false))
      equal(srgb.get('notesVerb'), 'PUT')
    })
  })

  QUnit.module('includeUngradedAssignments', hooks => {
    hooks.beforeEach(() => {
      initializeApp()

      window.ENV.GRADEBOOK_OPTIONS = {}
      window.ENV.GRADEBOOK_OPTIONS.settings = {}
    })

    QUnit.module('when storing in Gradebook preferences', gbHooks => {
      gbHooks.beforeEach(() => {
        window.ENV.GRADEBOOK_OPTIONS.save_view_ungraded_as_zero_to_server = true
      })

      test('returns true when the setting is passed as "true"', () => {
        window.ENV.GRADEBOOK_OPTIONS.settings.view_ungraded_as_zero = 'true'
        userSettings.contextGet.withArgs('include_ungraded_assignments').returns(false)
        strictEqual(srgb.get('includeUngradedAssignments'), true)
      })

      test('returns false when the setting is passed as "false"', () => {
        window.ENV.GRADEBOOK_OPTIONS.settings.view_ungraded_as_zero = 'false'
        userSettings.contextGet.withArgs('include_ungraded_assignments').returns(true)
        strictEqual(srgb.get('includeUngradedAssignments'), false)
      })

      test('falls back to the value in localStorage when no setting value is present', () => {
        userSettings.contextGet.withArgs('include_ungraded_assignments').returns(true)
        strictEqual(srgb.get('includeUngradedAssignments'), true)
      })

      test('returns false if no value exists in localStorage or in settings', () => {
        strictEqual(srgb.get('includeUngradedAssignments'), false)
      })

      test('returns the last-set value after being set', () => {
        srgb.set('includeUngradedAssignments', true)
        strictEqual(srgb.get('includeUngradedAssignments'), true)
      })
    })

    QUnit.module('when storing settings locally', () => {
      test('returns true when include_ungraded_assignments is true', () => {
        userSettings.contextGet.withArgs('include_ungraded_assignments').returns(true)
        strictEqual(srgb.get('includeUngradedAssignments'), true)
      })

      test('returns false when include_ungraded_assignments is false', () => {
        userSettings.contextGet.withArgs('include_ungraded_assignments').returns(false)
        strictEqual(srgb.get('includeUngradedAssignments'), false)
      })
    })
  })

  QUnit.module('updateIncludeUngradedAssignmentsSetting', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
    })

    QUnit.module('when storing settings in Gradebook preferences', gbHooks => {
      gbHooks.beforeEach(() => {
        window.ENV.GRADEBOOK_OPTIONS.save_view_ungraded_as_zero_to_server = true

        const url = `/api/v1/courses/${ENV.GRADEBOOK_OPTIONS.context_id}/gradebook_settings`
        ajax.defineFixture(url, {
          response: [],
          textStatus: 'success',
        })
      })

      test('updateIncludeUngradedAssignmentsSetting uses the Gradebook settings endpoint', () => {
        const ajaxRequestSpy = sandbox.stub(ajax, 'request')
        const url = `/api/v1/courses/${ENV.GRADEBOOK_OPTIONS.context_id}/gradebook_settings`
        srgb.set('includeUngradedAssignments', false)
        strictEqual(ajaxRequestSpy.firstCall.args[0].url, url)
      })

      test('updateIncludeUngradedAssignmentsSetting passes the updated setting state', () => {
        const ajaxRequestSpy = sandbox.stub(ajax, 'request')
        srgb.set('includeUngradedAssignments', false)
        deepEqual(ajaxRequestSpy.firstCall.args[0].data, {
          gradebook_settings: {
            view_ungraded_as_zero: 'false',
          },
        })
      })
    })

    QUnit.module('when storing settings locally (2)', () => {
      test('updateIncludeUngradedAssignmentsSetting does not call the Gradebook settings endpoint', () => {
        const ajaxRequestSpy = sandbox.stub(ajax, 'request')
        srgb.set('includeUngradedAssignments', false)
        equal(ajaxRequestSpy.callCount, 0)
      })
    })

    test('changing includeUngradedAssignments calls updateIncludeUngradedAssignmentsSetting', () => {
      const updateIncludeUngradedAssignmentsSettingStub = sinon.stub(
        srgb,
        'updateIncludeUngradedAssignmentsSetting'
      )
      srgb.set('includeUngradedAssignments', false)
      strictEqual(updateIncludeUngradedAssignmentsSettingStub.callCount, 1)
    })

    test('updateIncludeUngradedAssignmentsSetting sets the userSetting for include_ungraded_assignments', () => {
      srgb.set('includeUngradedAssignments', false)
      strictEqual(userSettings.contextSet.firstCall.args[0], 'include_ungraded_assignments')
    })

    test('updateIncludeUngradedAssignmentsSetting updates the setting value', () => {
      srgb.set('includeUngradedAssignments', false)
      strictEqual(userSettings.contextSet.firstCall.args[1], false)
    })
  })

  QUnit.module('showConcludedEnrollments', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.settings = {}
      initializeApp()
    })

    test('returns true when show_concluded_enrollments is true', () => {
      window.ENV.GRADEBOOK_OPTIONS.settings.show_concluded_enrollments = 'true'
      strictEqual(srgb.get('showConcludedEnrollments'), true)
    })

    test('returns false when show_concluded_enrollments is false', () => {
      window.ENV.GRADEBOOK_OPTIONS.settings.show_concluded_enrollments = 'false'
      strictEqual(srgb.get('showConcludedEnrollments'), false)
    })
  })

  QUnit.module('updateShowConcludedEnrollmentsSetting', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.settings = {}
      window.ENV.GRADEBOOK_OPTIONS.settings.show_concluded_enrollments = 'true'
      window.ENV.GRADEBOOK_OPTIONS.settings_update_url = 'gradebook_settings'
      ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.settings.settings_update_url, {
        response: [],
        textStatus: 'success',
      })
      initializeApp()
      sinon.stub(srgb, 'fetchCorrectEnrollments')
    })

    test('changing showConcludedEnrollments calls updateShowConcludedEnrollmentsSetting', () => {
      const updateShowConcludedEnrollmentsSettingStub = sinon.stub(
        srgb,
        'updateShowConcludedEnrollmentsSetting'
      )
      srgb.set('showConcludedEnrollments', false)
      strictEqual(updateShowConcludedEnrollmentsSettingStub.callCount, 1)
    })

    test('updateShowConcludedEnrollmentsSetting uses the gradebook settings endpoint', () => {
      const ajaxRequestSpy = sandbox.stub(ajax, 'request')
      srgb.set('showConcludedEnrollments', false)
      strictEqual(ajaxRequestSpy.firstCall.args[0].url, 'gradebook_settings')
    })

    test('updateShowConcludedEnrollmentsSetting passes the updated setting state', () => {
      const ajaxRequestSpy = sandbox.stub(ajax, 'request')
      srgb.set('showConcludedEnrollments', false)
      deepEqual(ajaxRequestSpy.firstCall.args[0].data.gradebook_settings, {
        show_concluded_enrollments: false,
      })
    })
  })

  QUnit.module('finalGradeOverrideEnabled', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
    })

    test('returns true when final_grade_override_enabled is true', () => {
      window.ENV.GRADEBOOK_OPTIONS.final_grade_override_enabled = true
      strictEqual(srgb.get('finalGradeOverrideEnabled'), true)
    })

    test('returns false when final_grade_override_enabled is false', () => {
      window.ENV.GRADEBOOK_OPTIONS.final_grade_override_enabled = false
      strictEqual(srgb.get('finalGradeOverrideEnabled'), false)
    })
  })

  QUnit.module('allowFinalGradeOverride', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.course_settings = {}
      initializeApp()
    })

    test('returns true when allow_final_grade_override is true', () => {
      window.ENV.GRADEBOOK_OPTIONS.course_settings.allow_final_grade_override = true
      strictEqual(srgb.get('allowFinalGradeOverride'), true)
    })

    test('returns false when allow_final_grade_override is false', () => {
      window.ENV.GRADEBOOK_OPTIONS.course_settings.allow_final_grade_override = false
      strictEqual(srgb.get('allowFinalGradeOverride'), false)
    })
  })

  QUnit.module('updateAllowFinalGradeOverride', hooks => {
    hooks.beforeEach(() => {
      window.ENV.GRADEBOOK_OPTIONS.course_settings = {}
      window.ENV.GRADEBOOK_OPTIONS.course_settings.allow_final_grade_override = true
      ajax.defineFixture(`/api/v1/courses/${ENV.GRADEBOOK_OPTIONS.context_id}/settings`, {
        response: [],
        textStatus: 'success',
      })
      initializeApp()
    })

    test('changing allowFinalGradeOverride calls updateAllowFinalGradeOverride', () => {
      const updateAllowFinalGradeOverrideStub = sinon.stub(srgb, 'updateAllowFinalGradeOverride')
      srgb.set('allowFinalGradeOverride', false)
      strictEqual(updateAllowFinalGradeOverrideStub.callCount, 1)
    })

    test('updateAllowFinalGradeOverride uses the course settings endpoint', () => {
      const ajaxRequestSpy = sandbox.stub(ajax, 'request')
      const url = `/api/v1/courses/${ENV.GRADEBOOK_OPTIONS.context_id}/settings`
      srgb.set('allowFinalGradeOverride', false)
      strictEqual(ajaxRequestSpy.firstCall.args[0].url, url)
    })

    test('updateAllowFinalGradeOverride passes the updated setting state', () => {
      const ajaxRequestSpy = sandbox.stub(ajax, 'request')
      srgb.set('allowFinalGradeOverride', false)
      deepEqual(ajaxRequestSpy.firstCall.args[0].data, {
        allow_final_grade_override: false,
      })
    })
  })

  QUnit.module('selectedStudentFinalGradeOverrideChanged', hooks => {
    let student
    let student2

    hooks.beforeEach(() => {
      initializeApp()

      // These observe the selectedGradingPeriod, so tests setting that
      // property will trigger these unless stubbed out.
      sinon.stub(srgb, 'fetchStudentSubmissions')
      sinon.stub(srgb, 'fetchAssignmentGroups')
      sinon.stub(srgb, 'calculateStudentGrade')
      student = srgb.get('students.firstObject')
      student2 = {...student, id: student.id + 100}

      srgb.set('selectedStudent', student)
      srgb.set(
        'final_grade_overrides',
        ObjectProxy.create({
          content: {
            finalGradeOverrides: {
              [student.id]: {
                courseGrade: {
                  percentage: 67.1,
                },
                gradingPeriodGrades: {
                  1: {
                    percentage: 93.2,
                  },
                },
              },
              [student2.id]: {
                courseGrade: {
                  percentage: 1,
                },
              },
            },
          },
          isLoaded: true,
        })
      )
    })

    test('sets selectedStudentFinalGradeOverride to the grading period override', () => {
      const selectedGradingPeriod = {id: '1'}
      srgb.set('selectedGradingPeriod', selectedGradingPeriod)
      strictEqual(srgb.get('selectedStudentFinalGradeOverride.percentage'), 93.2)
    })

    test('sets selectedStudentFinalGradeOverride to the course override', () => {
      const selectedGradingPeriod = {id: '0'}
      srgb.set('selectedGradingPeriod', selectedGradingPeriod)
      strictEqual(srgb.get('selectedStudentFinalGradeOverride.percentage'), 67.1)
    })

    test('sets selectedStudentFinalGradeOverride to the course override if no grading period', () => {
      strictEqual(srgb.get('selectedStudentFinalGradeOverride.percentage'), 67.1)
    })

    test('changing final_grade_overrides updates selectedStudentFinalGradeOverride', () => {
      const overrides = srgb.get('final_grade_overrides.content.finalGradeOverrides')
      overrides[student.id].courseGrade.percentage = 91
      srgb.set('final_grade_overrides.content', {finalGradeOverrides: overrides})
      strictEqual(srgb.get('selectedStudentFinalGradeOverride.percentage'), 91)
    })

    test('changing selectedStudent updates selectedStudentFinalGradeOverride', () => {
      srgb.set('selectedStudent', student2)
      strictEqual(srgb.get('selectedStudentFinalGradeOverride.percentage'), 1)
    })

    test('changing to a student without grading period overrides does not cause an error', () => {
      const selectedGradingPeriod = {id: '1'}
      srgb.set('selectedGradingPeriod', selectedGradingPeriod)
      srgb.set('selectedStudent', student2)
      deepEqual(srgb.get('selectedStudentFinalGradeOverride'), {})
    })
  })

  QUnit.module('onEditFinalGradeOverride', hooks => {
    let student
    let updateFinalGradeOverrideStub

    hooks.beforeEach(() => {
      initializeApp()

      // These observe the selectedGradingPeriod, so tests setting that
      // property will trigger these unless stubbed out.
      sinon.stub(srgb, 'fetchStudentSubmissions')
      sinon.stub(srgb, 'fetchAssignmentGroups')
      sinon.stub(srgb, 'calculateStudentGrade')
      student = srgb.get('students.firstObject')

      srgb.set('selectedStudent', student)
      srgb.set(
        'final_grade_overrides',
        ObjectProxy.create({
          content: {
            finalGradeOverrides: {
              [student.id]: {
                courseGrade: {
                  percentage: 67.1,
                },
                gradingPeriodGrades: {
                  1: {
                    percentage: 93.2,
                  },
                },
              },
            },
          },
          isLoaded: true,
        })
      )

      updateFinalGradeOverrideStub = sandbox.stub(FinalGradeOverrideApi, 'updateFinalGradeOverride')
    })

    test('given an invalid grade, final_grade_overrides is unchanged', () => {
      srgb.send('onEditFinalGradeOverride', 'howdy doody')
      const overrides = srgb.get('final_grade_overrides').content.finalGradeOverrides[student.id]
      strictEqual(overrides.courseGrade.percentage, 67.1)
    })

    test('given an invalid grade, the overrides endpoint is not hit', () => {
      srgb.send('onEditFinalGradeOverride', 'howdy doody')
      strictEqual(updateFinalGradeOverrideStub.callCount, 0)
    })

    test('given an unchanged grade, the overrides endpoint is not hit', () => {
      srgb.send('onEditFinalGradeOverride', 67.1)
      strictEqual(updateFinalGradeOverrideStub.callCount, 0)
    })

    test('given a changed, valid grade, final_grade_overrides is updated for grading period', () => {
      const gradingPeriod = {id: '1'}
      srgb.set('selectedGradingPeriod', gradingPeriod)
      srgb.send('onEditFinalGradeOverride', 91)
      const overrides = srgb.get('final_grade_overrides').content.finalGradeOverrides[student.id]
      const gradingPeriodOverride = overrides.gradingPeriodGrades[gradingPeriod.id]
      strictEqual(gradingPeriodOverride.percentage, 91)
    })

    test('given a new, valid grade, final_grade_overrides is updated for the student', () => {
      const student2 = {...student, id: student.id + 100}
      Ember.run(() => {
        const enrollments = {content: [{id: 1, user_id: student2.id}]}
        srgb.set('enrollments', enrollments)
      })
      srgb.set('selectedStudent', student2)
      srgb.send('onEditFinalGradeOverride', 100)
      const overrides = srgb.get('final_grade_overrides.content.finalGradeOverrides')[student2.id]
      strictEqual(overrides.courseGrade.percentage, 100)
    })

    test('when no override exists for a grading period, a valid grade is accepted without issue', () => {
      srgb.set('gradingPeriods', [{id: '1'}, {id: '9001'}])
      srgb.set('selectedGradingPeriod', {id: '9001'})
      srgb.send('onEditFinalGradeOverride', 100)
      strictEqual(true, true)
    })

    test('given a changed, valid grade, selectedStudentFinalGradeOverride is updated for course', () => {
      srgb.send('onEditFinalGradeOverride', 91)
      const overrides = srgb.get('final_grade_overrides').content.finalGradeOverrides[student.id]
      strictEqual(overrides.courseGrade.percentage, 91)
    })

    test('given a changed, valid grade, the overrides endpoint is hit', () => {
      srgb.send('onEditFinalGradeOverride', 91)
      strictEqual(updateFinalGradeOverrideStub.callCount, 1)
    })

    test('given a changed, valid grade, the overrides endpoint is passed the enrollment id', () => {
      // Setting enrollments without Ember.run has asynchronous side-effects.
      Ember.run(() => {
        const enrollments = {content: [{id: 1, user_id: student.id}]}
        srgb.set('enrollments', enrollments)
      })
      srgb.send('onEditFinalGradeOverride', 91)
      strictEqual(updateFinalGradeOverrideStub.firstCall.args[0], 1)
    })

    test('given a changed, valid grade, the overrides endpoint is passed the grading period id', () => {
      const gradingPeriod = {id: '1'}
      srgb.set('selectedGradingPeriod', gradingPeriod)
      srgb.send('onEditFinalGradeOverride', 91)
      strictEqual(updateFinalGradeOverrideStub.firstCall.args[1], '1')
    })

    test('given a changed, valid grade, the overrides endpoint is passed null when no grading period is selected', () => {
      srgb.send('onEditFinalGradeOverride', 91)
      strictEqual(updateFinalGradeOverrideStub.firstCall.args[1], null)
    })

    test('given a changed, valid grade, the overrides endpoint is passed the new override grade', () => {
      srgb.send('onEditFinalGradeOverride', 91)
      strictEqual(updateFinalGradeOverrideStub.firstCall.args[2].percentage, 91)
    })
  })

  QUnit.module('Invalid Assignment Groups', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper
        .waitForRequests()
        .then(() =>
          Ember.run(() =>
            srgb.set(
              'assignment_groups',
              Ember.ArrayProxy.create({content: clone(fixtures.assignment_groups)})
            )
          )
        )
    })

    test('calculates invalidGroupsWarningPhrases properly', () =>
      equal(
        srgb.get('invalidGroupsWarningPhrases'),
        'Note: Score does not include assignments from the group Invalid AG because it has no points possible.'
      ))

    test('sets showInvalidGroupWarning to false when assignment groups are not weighted', () =>
      Ember.run(() => {
        srgb.set('weightingScheme', 'equal')
        equal(srgb.get('showInvalidGroupWarning'), false)
      }))

    test('sets showInvalidGroupWarning to false when assignment groups are weighted', () =>
      Ember.run(() => {
        srgb.set('weightingScheme', 'percent')
        equal(srgb.get('showInvalidGroupWarning'), true)
      }))
  })

  QUnit.module('Differentiated Assignments', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper.waitForRequests()
    })

    test('selectedSubmissionHidden is false when students have visibility', () => {
      const student = srgb.get('students.firstObject')
      const assignment = srgb.get('assignments.firstObject')

      return Ember.run(() => {
        srgb.set('selectedAssignment', assignment)
        srgb.set('selectedStudent', student)
        equal(srgb.get('selectedSubmissionHidden'), false)
      })
    })

    test('selectedSubmissionHidden is true when students dont have visibility', () => {
      const student = srgb.get('students').objectAt(2)
      const assignment = srgb.get('assignments.firstObject')

      return Ember.run(() => {
        srgb.set('selectedAssignment', assignment)
        srgb.set('selectedStudent', student)
        equal(srgb.get('selectedSubmissionHidden'), true)
      })
    })
  })

  QUnit.module('anonymizeStudents', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper.waitForRequests()
    })

    test('false when anonymize_students is false', () => {
      const assignment = srgb.get('assignments.firstObject')
      assignment.anonymize_students = false

      return Ember.run(() => {
        srgb.set('selectedAssignment', assignment)
        equal(srgb.get('anonymizeStudents'), false)
      })
    })

    test('true when anonymize_students is true', () => {
      const assignment = srgb.get('assignments.firstObject')
      assignment.anonymize_students = true

      return Ember.run(() => {
        srgb.set('selectedAssignment', assignment)
        equal(srgb.get('anonymizeStudents'), true)
      })
    })
  })

  QUnit.module('selectedOutcomeResult', hooks => {
    hooks.beforeEach(() => {
      initializeApp()
      return asyncHelper.waitForRequests()
    })

    test('returns object including mastery_points if result is found', () => {
      const student = srgb.get('students.firstObject')
      const outcome = srgb.get('outcomes.firstObject')

      return Ember.run(() => {
        srgb.set('selectedOutcome', outcome)
        srgb.set('selectedStudent', student)
        equal(srgb.get('selectedOutcomeResult').mastery_points, outcome.mastery_points)
      })
    })
  })
})
