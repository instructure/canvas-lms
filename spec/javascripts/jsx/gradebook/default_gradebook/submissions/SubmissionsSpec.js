/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook > Submissions', suiteHooks => {
  let $container
  let gradebook
  let gradebookOptions

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)

    gradebookOptions = {}
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  QUnit.module('#updateSubmissionsLoaded()', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook(gradebookOptions)
    })

    test('optionally sets the submissions loaded status to true', () => {
      gradebook.updateSubmissionsLoaded(true)
      strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
    })

    test('optionally sets the submissions loaded status to false', () => {
      gradebook.updateSubmissionsLoaded(false)
      strictEqual(gradebook.contentLoadStates.submissionsLoaded, false)
    })

    test('updates column headers', () => {
      sinon.spy(gradebook, 'updateColumnHeaders')
      gradebook.updateSubmissionsLoaded(true)
      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
    })

    test('updates column headers after updating the students loaded status', () => {
      sinon.stub(gradebook, 'updateColumnHeaders').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
      })
      gradebook.updateSubmissionsLoaded(true)
    })

    test('renders filters', () => {
      sinon.spy(gradebook, 'renderFilters')
      gradebook.updateSubmissionsLoaded(true)
      strictEqual(gradebook.renderFilters.callCount, 1)
    })

    test('renders filters after updating the submissions loaded status', () => {
      sinon.stub(gradebook, 'renderFilters').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
      })
      gradebook.updateSubmissionsLoaded(true)
    })

    test('updates the total grade column when submissions and students are loaded', () => {
      gradebook.setStudentsLoaded(true)
      sinon.spy(gradebook, 'updateTotalGradeColumn')
      gradebook.updateSubmissionsLoaded(true)
      strictEqual(gradebook.updateTotalGradeColumn.callCount, 1)
    })

    test('updates the total grade column after updating the submissions loaded status', () => {
      gradebook.setStudentsLoaded(true)
      sinon.stub(gradebook, 'updateTotalGradeColumn').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
      })
      gradebook.updateSubmissionsLoaded(true)
    })

    test('does not update the total grade column when students are not loaded', () => {
      gradebook.setStudentsLoaded(false)
      sinon.spy(gradebook, 'updateTotalGradeColumn')
      gradebook.updateSubmissionsLoaded(true)
      strictEqual(gradebook.updateTotalGradeColumn.callCount, 0)
    })

    test('does not update the total grade column when submissions are not loaded', () => {
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      sinon.spy(gradebook, 'updateTotalGradeColumn')
      gradebook.updateSubmissionsLoaded(false)
      strictEqual(gradebook.updateTotalGradeColumn.callCount, 0)
    })
  })

  QUnit.module('#gotSubmissionsChunk()', hooks => {
    let studentSubmissions

    hooks.beforeEach(() => {
      gradebook = createGradebook(gradebookOptions)

      const students = [
        {
          enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
          id: '1101',
          name: 'Adam Jones',
        },
        {
          enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
          id: '1102',
          name: 'Betty Ford',
        },
      ]

      gradebook.gotChunkOfStudents(students)
      sinon.spy(gradebook, 'setupGrading')

      studentSubmissions = [
        {
          submissions: [
            {
              assignment_id: '2301',
              assignment_visible: true,
              cached_due_date: '2015-10-15T12:00:00Z',
              id: '2501',
              score: 10,
              user_id: '1101',
            },

            {
              assignment_id: '2302',
              assignment_visible: true,
              cached_due_date: '2015-12-15T12:00:00Z',
              id: '2502',
              score: 9,
              user_id: '1101',
            },
          ],

          user_id: '1101',
        },

        {
          submissions: [
            {
              assignment_id: '2301',
              assignment_visible: true,
              cached_due_date: '2015-10-16T12:00:00Z',
              id: '2503',
              score: 10,
              user_id: '1102',
            },
          ],

          user_id: '1102',
        },
      ]

      gradebook.setAssignmentGroups({
        2201: {group_weight: 100},
      })

      gradebook.setAssignments({
        2301: {
          assignment_group_id: '2201',
          id: '2301',
          name: 'Math Assignment',
          published: true,
        },

        2302: {
          assignment_group_id: '2201',
          id: '2302',
          name: 'English Assignment',
          published: false,
        },
      })
    })

    function getEffectiveDueDates(assignmentId) {
      return gradebook.effectiveDueDates[assignmentId]
    }

    function getAssignment(assignmentId) {
      return gradebook.getAssignment(assignmentId)
    }

    test('updates effective due dates with the submissions', () => {
      gradebook.gotSubmissionsChunk(studentSubmissions)
      deepEqual(Object.keys(getEffectiveDueDates('2301')), ['1101', '1102'])
    })

    test('sets .effectiveDueDates on related assignments', () => {
      gradebook.gotSubmissionsChunk(studentSubmissions)
      deepEqual(Object.keys(getAssignment('2301').effectiveDueDates), ['1101', '1102'])
    })

    test('sets .inClosedGradingPeriod on related assignments', () => {
      gradebook.gotSubmissionsChunk(studentSubmissions)
      strictEqual(gradebook.getAssignment('2301').inClosedGradingPeriod, false)
    })

    test('sets up grading', () => {
      gradebook.gotSubmissionsChunk(studentSubmissions)
      strictEqual(gradebook.setupGrading.callCount, 1)
    })

    test('uses the ids of the related students to set up grading', () => {
      gradebook.gotSubmissionsChunk(studentSubmissions)
      const [students] = gradebook.setupGrading.lastCall.args
      deepEqual(
        students.map(student => student.id),
        ['1101', '1102']
      )
    })

    QUnit.module('when the assignment is only visible to overrides', contextHooks => {
      contextHooks.beforeEach(() => {
        const assignment = getAssignment('2301')
        assignment.only_visible_to_overrides = true
        assignment.assignment_visibility = []
      })

      test('updates the assignment visibility when the student submitted to the assignment', () => {
        gradebook.gotSubmissionsChunk(studentSubmissions)
        deepEqual(getAssignment('2301').assignment_visibility, ['1101', '1102'])
      })

      test('does not add duplicate students to assignment visibility', () => {
        const assignment = getAssignment('2301')
        assignment.assignment_visibility = ['1101', '1102']
        gradebook.gotSubmissionsChunk(studentSubmissions)
        deepEqual(getAssignment('2301').assignment_visibility, ['1101', '1102'])
      })
    })

    test('does not update assignment visibility when not only visible to overrides', () => {
      const assignment = getAssignment('2301')
      assignment.only_visible_to_overrides = false
      assignment.assignment_visibility = []
      gradebook.gotSubmissionsChunk(studentSubmissions)
      deepEqual(getAssignment('2301').assignment_visibility, [])
    })

    test('does nothing when the assignment is not loaded in Gradebook', () => {
      studentSubmissions[0].submissions[1].assignment_id = '2309'
      gradebook.gotSubmissionsChunk(studentSubmissions)
      equal(getAssignment('2309'), null)
    })
  })

  QUnit.module('#submissionsForStudent()', hooks => {
    let studentSubmissions

    hooks.beforeEach(() => {
      gradebookOptions.grading_period_set = {
        display_totals_for_all_grading_periods: false,
        grading_periods: [
          {
            close_date: '2015-11-07T12:00:00Z',
            end_date: '2015-11-01T12:00:00Z',
            id: '1501',
            start_date: '2015-09-01T12:00:00Z',
            title: 'Q1',
            weight: null,
          },

          {
            close_date: '2016-01-07T12:00:00Z',
            end_date: '2015-12-31T12:00:00Z',
            id: '1502',
            start_date: '2015-11-01T12:00:00Z',
            title: 'Q2',
            weight: null,
          },
        ],

        id: '1401',
        title: 'Fall 2015',
        weighted: false,
      }

      studentSubmissions = [
        {
          submissions: [
            {
              assignment_id: '2301',
              assignment_visible: true,
              cached_due_date: '2015-10-15T12:00:00Z',
              id: '2501',
              score: 10,
              user_id: '1101',
            },

            {
              assignment_id: '2302',
              assignment_visible: true,
              cached_due_date: '2015-12-15T12:00:00Z',
              id: '2502',
              score: 9,
              user_id: '1101',
            },
          ],

          user_id: '1101',
        },
      ]
    })

    function createGradebookAndLoadData() {
      const students = [
        {
          enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
          id: '1101',
          name: 'Adam Jones',
        },
      ]

      gradebook = createGradebook(gradebookOptions)
      gradebook.gotChunkOfStudents(students)

      gradebook.setAssignmentGroups({
        2201: {group_weight: 100},
      })

      gradebook.setAssignments({
        2301: {
          assignment_group_id: '2201',
          id: '2301',
          name: 'Math Assignment',
          published: true,
        },

        2302: {
          assignment_group_id: '2201',
          id: '2302',
          name: 'English Assignment',
          published: false,
        },
      })

      gradebook.gotSubmissionsChunk(studentSubmissions)
    }

    function getSubmissionIds() {
      const student = gradebook.student('1101')
      return gradebook.submissionsForStudent(student).map(submission => submission.id)
    }

    QUnit.module('when using grading periods', () => {
      test('returns all submissions for the student when not filtering by grading period', () => {
        gradebookOptions.current_grading_period_id = null
        createGradebookAndLoadData()
        // Select "All Grading Periods"
        gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
        gradebook.setCurrentGradingPeriod()
        deepEqual(getSubmissionIds().sort(), ['2501', '2502'])
      })

      QUnit.module('when filtering to a selected grading period', () => {
        test('includes only submissions due in the selected grading period', () => {
          gradebookOptions.current_grading_period_id = '1501'
          createGradebookAndLoadData()
          // Select "Q2"
          gradebook.setFilterColumnsBySetting('gradingPeriodId', '1502')
          gradebook.setCurrentGradingPeriod()
          deepEqual(getSubmissionIds(), ['2502'])
        })
      })

      QUnit.module('when implicitly filtering to the current grading period', () => {
        test('includes only submissions due in the current grading period', () => {
          // Use the current grading period
          gradebookOptions.current_grading_period_id = '1501'
          createGradebookAndLoadData()
          deepEqual(getSubmissionIds(), ['2501'])
        })
      })
    })

    QUnit.module('when not using grading periods', () => {
      test('returns all submissions for the student', () => {
        gradebookOptions.grading_period_set = null
        createGradebookAndLoadData()
        deepEqual(getSubmissionIds().sort(), ['2501', '2502'])
      })
    })
  })

  QUnit.module('#updateSubmission()', hooks => {
    let submission

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.students = {1101: {id: '1101'}}

      gradebook.assignments[2301] = {
        grading_type: 'percent',
        id: '2301',
        name: 'Math Assignment',
        published: true,
      }

      submission = {
        assignment_id: '2301',
        grade: '123.45',
        submitted_at: '2015-05-04T12:00:00Z',
        user_id: '1101',
      }
    })

    function getSubmission() {
      return gradebook.getSubmission('1101', '2301')
    }

    test('formats the grade for the submission', () => {
      sandbox.spy(GradeFormatHelper, 'formatGrade')
      gradebook.updateSubmission(submission)
      equal(GradeFormatHelper.formatGrade.callCount, 1)
    })

    test('includes the grade when formatting the grade', () => {
      sandbox.spy(GradeFormatHelper, 'formatGrade')
      gradebook.updateSubmission(submission)
      const [grade] = GradeFormatHelper.formatGrade.getCall(0).args
      strictEqual(grade, '123.45', 'parameter 1 is the submission grade')
    })

    test('includes the grading type when formatting the grade', () => {
      sandbox.spy(GradeFormatHelper, 'formatGrade')
      gradebook.updateSubmission(submission)
      const [, options] = GradeFormatHelper.formatGrade.getCall(0).args
      equal(options.gradingType, 'percent', 'options.gradingType is the submission gradingType')
    })

    test('does not delocalize when formatting the grade', () => {
      sandbox.spy(GradeFormatHelper, 'formatGrade')
      gradebook.updateSubmission(submission)
      const [, options] = GradeFormatHelper.formatGrade.getCall(0).args
      strictEqual(options.delocalize, false, 'submission grades from the server are not localized')
    })

    test('sets the formatted grade on submission', () => {
      sandbox.stub(GradeFormatHelper, 'formatGrade').returns('123.45%')
      gradebook.updateSubmission(submission)
      equal(getSubmission().grade, '123.45%')
    })

    test('sets the raw grade on submission', () => {
      sandbox.stub(GradeFormatHelper, 'formatGrade').returns('123.45%')
      gradebook.updateSubmission(submission)
      strictEqual(getSubmission().rawGrade, '123.45')
    })

    test('sets the submission as not hidden when implicitly not hidden', () => {
      delete submission.hidden
      gradebook.updateSubmission(submission)
      strictEqual(getSubmission().hidden, false)
    })

    test('keeps the submission hidden when previously hidden', () => {
      submission.hidden = true
      gradebook.updateSubmission(submission)
      strictEqual(getSubmission().hidden, true)
    })

    test('keeps the submission as not hidden when previously not hidden', () => {
      submission.hidden = false
      gradebook.updateSubmission(submission)
      strictEqual(getSubmission().hidden, false)
    })

    test('does not format grades when the assignment has not loaded', () => {
      sandbox.spy(GradeFormatHelper, 'formatGrade')
      delete gradebook.assignments[2301]
      gradebook.updateSubmission(submission)
      strictEqual(GradeFormatHelper.formatGrade.callCount, 0)
    })

    test('does not format grades for Complete/Incomplete assignments', () => {
      /*
       * When the grades ('complete', 'incomplete') for these assignments
       * are formatted, they are translated to the user's locale. This means
       * they cannot be used in comparisons elsewhere in Gradebook. Prevent
       * this from happening. Eventually, grades will be purely the persisted,
       * data values from the database. And formatting will occur only in the UI.
       */
      sandbox.spy(GradeFormatHelper, 'formatGrade')
      gradebook.assignments[2301].grading_type = 'pass_fail'
      gradebook.updateSubmission(submission)
      strictEqual(GradeFormatHelper.formatGrade.callCount, 0)
    })
  })

  QUnit.module('#updateSubmissionsFromExternal()', hooks => {
    hooks.beforeEach(() => {
      const columns = [
        {id: 'student', type: 'student'},
        {id: 'assignment_2301', type: 'assignment'},
        {id: 'assignment_2302', type: 'assignment'},
        {id: 'assignment_group_2201', type: 'assignment_group'},
        {id: 'assignment_group_2202', type: 'assignment_group'},
        {id: 'total_grade', type: 'total_grade'},
      ]

      const studentData = [
        {
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1101'},
              type: 'StudentEnrollment',
            },
          ],
          id: '1101',
          name: 'Adam Jones',
        },

        {
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1102'},
              type: 'StudentEnrollment',
            },
          ],
          id: '1102',
          name: 'Betty Ford',
        },
      ]

      gradebook = createGradebook()

      gradebook.courseContent.students.setStudentIds(['1101', '1102'])
      gradebook.buildRows()

      gradebook.gotChunkOfStudents(studentData)

      const assignments = [
        {
          assignment_visibility: null,
          id: '2301',
          only_visible_to_overrides: false,
        },
        {
          assignment_visibility: null,
          id: '2302',
          only_visible_to_overrides: false,
        },
      ]

      gradebook.gotAllAssignmentGroups([
        {id: '2201', position: 1, name: 'Assignments', assignments: [assignments[0]]},
        {id: '2202', position: 2, name: 'Homework', assignments: [assignments[1]]},
      ])

      sinon.stub(gradebook, 'updateRowCellsForStudentIds')
      gradebook.resetGrading()

      gradebook.gradebookGrid.grid = {
        destroy() {},
        getColumns() {
          return columns
        },
        updateCell: sinon.stub(),
      }

      gradebook.gradebookGrid.gridSupport = {
        columns: {
          updateColumnHeaders: sinon.stub(),
        },
        destroy() {},
      }
    })

    test('updates row cells', () => {
      const submissions = [
        {assignment_id: '2301', user_id: '1101', score: 10, assignment_visible: true},
        {assignment_id: '2301', user_id: '1102', score: 8, assignment_visible: true},
      ]
      gradebook.updateSubmissionsFromExternal(submissions)
      strictEqual(gradebook.updateRowCellsForStudentIds.callCount, 1)
    })

    test('updates row cells only once for each student', () => {
      const submissions = [
        {assignment_id: '2301', user_id: '1101', score: 10, assignment_visible: true},
        {assignment_id: '2302', user_id: '1101', score: 9, assignment_visible: true},
        {assignment_id: '2301', user_id: '1102', score: 8, assignment_visible: true},
      ]
      gradebook.updateSubmissionsFromExternal(submissions)
      const [studentIds] = gradebook.updateRowCellsForStudentIds.lastCall.args
      deepEqual(studentIds, ['1101', '1102'])
    })

    test('ignores submissions for students not currently loaded', () => {
      const submissions = [
        {assignment_id: '2301', user_id: '1101', score: 10, assignment_visible: true},
        {assignment_id: '2301', user_id: '1103', score: 9, assignment_visible: true},
        {assignment_id: '2301', user_id: '1102', score: 8, assignment_visible: true},
      ]
      gradebook.updateSubmissionsFromExternal(submissions)
      const [studentIds] = gradebook.updateRowCellsForStudentIds.lastCall.args
      deepEqual(studentIds, ['1101', '1102'])
    })

    test('updates column headers', () => {
      const submissions = [
        {assignment_id: '2301', user_id: '1101', score: 10, assignment_visible: true},
      ]
      gradebook.updateSubmissionsFromExternal(submissions)
      strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
    })

    test('includes the column ids for related assignments when updating column headers', () => {
      const submissions = [
        {assignment_id: '2301', user_id: '1101', score: 10, assignment_visible: true},
        {assignment_id: '2302', user_id: '1101', score: 9, assignment_visible: true},
        {assignment_id: '2301', user_id: '1102', score: 8, assignment_visible: true},
      ]
      gradebook.updateSubmissionsFromExternal(submissions)
      const [columnIds] =
        gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
      deepEqual(columnIds.sort(), ['assignment_2301', 'assignment_2302'])
    })
  })
})
