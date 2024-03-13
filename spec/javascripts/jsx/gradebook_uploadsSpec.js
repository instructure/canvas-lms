/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import gradebook_uploads from 'ui/features/gradebook_uploads/jquery/index'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import * as waitForProcessing from 'ui/features/gradebook_uploads/jquery/wait_for_processing'

const fixtures = document.getElementById('fixtures')

QUnit.module('gradebook_uploads#createGeneralFormatter', hooks => {
  let formatter

  hooks.beforeEach(() => {
    formatter = gradebook_uploads.createGeneralFormatter('foo')
  })

  test('formatter returns expected lookup value', () => {
    const formatted = formatter(null, null, {foo: 'bar'})
    equal(formatted, 'bar')
  })

  test('formatter returns empty string when lookup value missing', () => {
    const formatted = formatter(null, null, null)
    equal(formatted, '')
  })

  test('formatter escapes passed-in HTML', () => {
    const formatted = formatter(null, null, {foo: 'bar & <baz>'})
    equal(formatted, 'bar &amp; &lt;baz&gt;')
  })
})

QUnit.module('gradebook_uploads#handleThingsNeedingToBeResolved', hooks => {
  let defaultUploadedGradebook

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <form id='gradebook_importer_resolution_section'>
        <select name='assignment_-1'>
          <option>73</option>
        </select>
      </form>
      <div id='gradebook_grid'>
        <div id='gradebook_grid_header'></div>
      </div>
      <div id='no_changes_detected' style='display:none;'></div>
    `

    defaultUploadedGradebook = {
      assignments: [
        {grading_type: null, id: '-1', points_possible: 10, previous_id: null, title: 'imported'},
      ],
      custom_columns: [],
      missing_objects: {
        assignments: [
          {
            grading_type: 'points',
            id: '73',
            points_possible: 10,
            previous_id: null,
            title: 'existing',
          },
        ],
        students: [],
      },
      original_submissions: [{assignment_id: '73', gradeable: true, score: '', user_id: '1'}],
      students: [
        {
          id: '1',
          last_name_first: 'Efron, Zac',
          name: 'Zac Efron',
          previous_id: '1',
          submissions: [{assignment_id: '-1', grade: '0.0', gradeable: true, original_grade: null}],
          custom_column_data: [],
        },
      ],
      warning_messages: {
        prevented_grading_ungradeable_submission: false,
        prevented_new_assignment_creation_in_closed_period: false,
      },
    }
  })

  hooks.afterEach(() => {
    fixtures.innerHTML = ''
  })

  test('recognizes that there are no changed assignments when the grades are the same', async () => {
    const uploadedGradebook = {
      ...defaultUploadedGradebook,
      original_submissions: [{assignment_id: '73', gradeable: true, score: '0.0', user_id: '1'}],
    }
    const waitForProcessingStub = sinon
      .stub(waitForProcessing, 'waitForProcessing')
      .resolves(uploadedGradebook)

    await gradebook_uploads.handleThingsNeedingToBeResolved()
    $('#gradebook_importer_resolution_section').submit()
    strictEqual($('#no_changes_detected:visible').length, 1)

    waitForProcessingStub.restore()
  })

  test('recognizes that there are changed assignments when original grade was ungraded', async () => {
    const uploadedGradebook = {
      ...defaultUploadedGradebook,
      original_submissions: [{assignment_id: '73', gradeable: true, score: '', user_id: '1'}],
    }
    const waitForProcessingStub = sinon
      .stub(waitForProcessing, 'waitForProcessing')
      .resolves(uploadedGradebook)

    await gradebook_uploads.handleThingsNeedingToBeResolved()
    $('#gradebook_importer_resolution_section').submit()
    strictEqual($('#no_changes_detected:visible').length, 0)

    waitForProcessingStub.restore()
  })
})

QUnit.module('grade_summary#createNumberFormatter')

test('number formatter returns empty string when value missing', () => {
  const formatter = gradebook_uploads.createNumberFormatter('foo')
  const formatted = formatter(null, null, null)
  equal(formatted, '')
})

test('number formatter delegates to GradeFormatHelper#formatGrade', () => {
  const formatGradeSpy = sandbox.spy(GradeFormatHelper, 'formatGrade')
  const formatter = gradebook_uploads.createNumberFormatter('foo')
  formatter(null, null, {})
  ok(formatGradeSpy.calledOnce)
})

QUnit.module('override score changes', hooks => {
  let gridStub
  let headerGridArgs
  let mainGridArgs
  let gradeReviewRow

  let defaultUploadedGradebook

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <div id='gradebook_grid'>
      </div>
      <div id='gradebook_grid_header'>
      </div>
    `

    defaultUploadedGradebook = {
      assignments: [
        {grading_type: null, id: '-1', points_possible: 10, previous_id: null, title: 'imported'},
      ],
      custom_columns: [],
      missing_objects: {
        assignments: [
          {
            grading_type: 'points',
            id: '73',
            points_possible: 10,
            previous_id: null,
            title: 'existing',
          },
        ],
        students: [],
      },
      original_submissions: [{assignment_id: '73', gradeable: true, score: '', user_id: '1'}],
      override_scores: {
        grading_periods: [
          {id: 1, title: 'first GP'},
          {id: 2, title: 'second GP'},
          {id: 3, title: 'third GP'},
        ],
        includes_course_scores: false,
      },
      override_statuses: {
        grading_periods: [
          {id: 1, title: 'first GP'},
          {id: 2, title: 'second GP'},
          {id: 3, title: 'third GP'},
        ],
        includes_course_score_status: false,
      },
      students: [
        {
          custom_column_data: [],
          id: '1',
          last_name_first: 'Efron, Zac',
          name: 'Zac Efron',
          override_scores: [
            {
              current_score: '70',
              grading_period_id: '1',
              new_score: '80',
            },
            {
              current_score: '71',
              grading_period_id: '2',
              new_score: '61',
            },
            {
              current_score: '50',
              new_score: null,
            },
          ],
          override_statuses: [
            {
              grading_period_id: '1',
              student_id: '1',
              current_grade_status: 'CARROT',
              new_grade_status: 'POTATO',
            },
            {
              grading_period_id: '2',
              student_id: '1',
              current_grade_status: null,
              new_grade_status: 'CARROT',
            },
            {
              grading_period_id: '3',
              student_id: '1',
              current_grade_status: 'POTATO',
              new_grade_status: null,
            },
          ],
          previous_id: '1',
          submissions: [{assignment_id: '-1', grade: '0.0', gradeable: true, original_grade: null}],
        },
      ],
      warning_messages: {
        prevented_grading_ungradeable_submission: false,
        prevented_new_assignment_creation_in_closed_period: false,
      },
    }

    gridStub = sinon.stub(gradebook_uploads, 'createGrid')

    // Creation of the actual grid, including "From" and "To" headers
    gridStub.onFirstCall().callsFake((_, {data, columns, options}) => {
      mainGridArgs = {data, columns, options}
      return {
        invalidateRow: () => {},
        render: () => {},
        setCellCssStyles: (_style, reviewRow) => {
          gradeReviewRow = reviewRow
        },
      }
    })

    // Creation of the ersatz grid containing headers, which is not
    // referenced after being created
    gridStub.onSecondCall().callsFake((_, {data, columns, options}) => {
      headerGridArgs = {data, columns, options}
      return {}
    })
  })

  hooks.afterEach(() => {
    gridStub.restore()
  })

  const initGradebook = function (uploadedGradebook = defaultUploadedGradebook) {
    gradebook_uploads.init(uploadedGradebook)
  }

  QUnit.module('column creation', () => {
    test('creates a pair of columns for each grading period in the grading_periods hash', () => {
      initGradebook()

      const columnIds = mainGridArgs.columns
        .map(column => column.id)
        .filter(id => id.includes('override_score'))

      deepEqual(columnIds, [
        'override_score_1_conflicting',
        'override_score_1',
        'override_score_2_conflicting',
        'override_score_2',
        'override_score_3_conflicting',
        'override_score_3',
      ])
    })

    test('adds a header for each grading period including the title of the grading period', () => {
      initGradebook()

      const headers = headerGridArgs.columns
        .map(column => column.name)
        .filter(name => name.includes('Override Score'))

      deepEqual(headers, [
        'Override Score (first GP)',
        'Override Score (second GP)',
        'Override Score (third GP)',
      ])
    })

    test('creates a column for course scores if includes_course_scores is true', () => {
      defaultUploadedGradebook.override_scores.includes_course_scores = true
      defaultUploadedGradebook.override_scores.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_score_course'
      )
      ok(gradingPeriodColumn)
    })

    test('adds a header for course scores with the label of plain old "Override Grade"', () => {
      defaultUploadedGradebook.override_scores.includes_course_scores = true
      defaultUploadedGradebook.override_scores.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = headerGridArgs.columns.find(
        column => column.name === 'Override Score'
      )
      ok(gradingPeriodColumn)
    })

    test('does not create a column for course scores if includes_course_scores is false', () => {
      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_score_course'
      )
      notOk(gradingPeriodColumn)
    })

    test('creates a pair of columns for each grading period in the grading_periods hash of override status', () => {
      initGradebook()

      const columnIds = mainGridArgs.columns
        .map(column => column.id)
        .filter(id => id.includes('override_status'))

      deepEqual(columnIds, [
        'override_status_1_conflicting',
        'override_status_1',
        'override_status_2_conflicting',
        'override_status_2',
        'override_status_3_conflicting',
        'override_status_3',
      ])
    })

    test('adds a header for each grading period including the title of the grading period of override status', () => {
      initGradebook()

      const headers = headerGridArgs.columns
        .map(column => column.name)
        .filter(name => name.includes('Override Status'))

      deepEqual(headers, [
        'Override Status (first GP)',
        'Override Status (second GP)',
        'Override Status (third GP)',
      ])
    })

    test('creates a column for course status if includes_course_score_status is true', () => {
      defaultUploadedGradebook.override_statuses.includes_course_score_status = true
      defaultUploadedGradebook.override_statuses.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_status_course'
      )
      ok(gradingPeriodColumn)
    })

    test('adds a header for course status with the label of plain old "Override Status"', () => {
      defaultUploadedGradebook.override_statuses.includes_course_score_status = true
      defaultUploadedGradebook.override_statuses.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = headerGridArgs.columns.find(
        column => column.name === 'Override Status'
      )
      ok(gradingPeriodColumn)
    })

    test('does not create a column for course status if includes_course_score_status is false', () => {
      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_status_course'
      )
      notOk(gradingPeriodColumn)
    })
  })

  QUnit.module('value population', () => {
    test('populates the grid data with course override scores for each student', () => {
      initGradebook()

      const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
      deepEqual(dataForStudent.override_score_course, {
        current_score: '50',
        new_score: null,
      })
    })

    test('populates the grid data with grading period override scores for each student', () => {
      initGradebook()

      const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
      deepEqual(dataForStudent.override_score_1, {
        current_score: '70',
        grading_period_id: '1',
        new_score: '80',
      })
    })

    test('highlights cells if the override score has gone down', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      strictEqual(
        firstStudentRow.override_score_2_conflicting,
        'left-highlight',
        'current score is highlighted'
      )
      strictEqual(
        firstStudentRow.override_score_2,
        'right-highlight',
        'updated (lowered) score is highlighted'
      )
    })

    test('highlights cells if the override score has been removed', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      strictEqual(
        firstStudentRow.override_score_course_conflicting,
        'left-highlight',
        'current score is highlighted'
      )
      strictEqual(
        firstStudentRow.override_score_course,
        'right-highlight',
        'updated (removed) score is highlighted'
      )
    })

    test('does not highlight cells if the override score has gone up', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      notOk(firstStudentRow.override_score_1_conflicting, 'current score is not highlighted')
      notOk(firstStudentRow.override_score_1, 'updated (increased) score is not highlighted')
    })

    test('does not highlight cells if the override score has not changed', () => {
      defaultUploadedGradebook.students[0].override_scores = [
        {
          current_score: '70',
          grading_period_id: '1',
          new_score: '70',
        },
      ]
      defaultUploadedGradebook.students[0].override_statuses = []
      initGradebook()

      // setCellCssStyles should be called with an empty hash since nothing to
      // highlight
      deepEqual(gradeReviewRow, {}, 'no highlightable changes')
    })

    test('does not highlight cells if the override score is newly added', () => {
      defaultUploadedGradebook.students[0].override_scores = [
        {
          current_score: null,
          grading_period_id: '1',
          new_score: '70',
        },
      ]
      defaultUploadedGradebook.students[0].override_statuses = []
      initGradebook()

      // setCellCssStyles should be called with an empty hash since nothing to
      // highlight
      deepEqual(gradeReviewRow, {}, 'no highlightable changes')
    })

    test('populates the grid data with course override statuses for each student', () => {
      defaultUploadedGradebook.override_statuses.includes_course_score_status = true
      defaultUploadedGradebook.override_statuses.grading_periods = []
      defaultUploadedGradebook.students[0].override_statuses = [
        {
          grading_period_id: null,
          student_id: '1',
          current_grade_status: 'BROCCOLI',
          new_grade_status: 'POTATO',
        },
      ]
      initGradebook()

      const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
      deepEqual(dataForStudent.override_status_course, {
        current_grade_status: 'BROCCOLI',
        new_grade_status: 'POTATO',
        grading_period_id: null,
        student_id: '1',
      })
    })

    test('populates the grid data with grading period override statuses for each student', () => {
      initGradebook()

      const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
      deepEqual(dataForStudent.override_status_1, {
        grading_period_id: '1',
        student_id: '1',
        current_grade_status: 'CARROT',
        new_grade_status: 'POTATO',
      })
    })

    test('highlights cells if the override status is changed', () => {
      initGradebook()
      const firstStudentRow = gradeReviewRow[0]
      strictEqual(
        firstStudentRow.override_status_1_conflicting,
        'left-highlight',
        'current status is highlighted'
      )
      strictEqual(
        firstStudentRow.override_status_1,
        'right-highlight',
        'updated status is highlighted'
      )
    })

    test('highlights cells if the override status has been removed', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      strictEqual(
        firstStudentRow.override_status_3_conflicting,
        'left-highlight',
        'current status is highlighted'
      )
      strictEqual(
        firstStudentRow.override_status_3,
        'right-highlight',
        'updated (removed) status is highlighted'
      )
    })
  })

  test('does not highlight the cells if the override status has been newly added', () => {
    defaultUploadedGradebook.students[0].override_scores = []
    defaultUploadedGradebook.students[0].override_statuses = [
      {
        grading_period_id: '1',
        student_id: '1',
        current_grade_status: null,
        new_grade_status: 'POTATO',
      },
    ]
    initGradebook()

    deepEqual(gradeReviewRow, {}, 'no highlightable changes')
  })

  test('does not highlight cells if the override status has not changed', () => {
    defaultUploadedGradebook.students[0].override_scores = []
    defaultUploadedGradebook.students[0].override_statuses = [
      {
        grading_period_id: '1',
        student_id: '1',
        current_grade_status: 'POTATO',
        new_grade_status: 'POTATO',
      },
    ]
    initGradebook()

    // setCellCssStyles should be called with an empty hash since nothing to
    // highlight
    deepEqual(gradeReviewRow, {}, 'no highlightable changes')
  })

  test('does not highlight cells if the override status case changed', () => {
    defaultUploadedGradebook.students[0].override_scores = []
    defaultUploadedGradebook.students[0].override_statuses = [
      {
        grading_period_id: '1',
        student_id: '1',
        current_grade_status: 'POTATO',
        new_grade_status: 'potato',
      },
    ]
    initGradebook()

    // setCellCssStyles should be called with an empty hash since nothing to
    // highlight
    deepEqual(gradeReviewRow, {}, 'no highlightable changes')
  })
})
