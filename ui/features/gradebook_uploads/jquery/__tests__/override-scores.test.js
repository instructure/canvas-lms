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

import $ from 'jquery'
import 'jquery-migrate'
import gradebook_uploads from '../index'

// Mock jQuery UI components
jest.mock('jquery-ui', () => {
  const $ = require('jquery')
  $.widget = jest.fn()
  $.ui = {
    mouse: {
      _mouseInit: jest.fn(),
      _mouseDestroy: jest.fn(),
    },
    sortable: jest.fn(),
  }
  return $
})

jest.mock('slickgrid', () => ({
  Grid: jest.fn().mockImplementation(() => ({
    init: jest.fn(),
    setData: jest.fn(),
    render: jest.fn(),
  })),
}))

describe('override score changes', () => {
  let gridStub
  let headerGridArgs
  let mainGridArgs
  let gradeReviewRow
  let defaultUploadedGradebook

  beforeEach(() => {
    document.body.innerHTML = `
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

    gridStub = jest.spyOn(gradebook_uploads, 'createGrid')

    // Creation of the actual grid, including "From" and "To" headers
    gridStub.mockImplementationOnce((_, {data, columns, options}) => {
      mainGridArgs = {data, columns, options}
      return {
        invalidateRow: () => {},
        render: () => {},
        setCellCssStyles: (_style, reviewRow) => {
          gradeReviewRow = reviewRow
        },
      }
    })

    // Creation of the ersatz grid containing headers
    gridStub.mockImplementationOnce((_, {data, columns, options}) => {
      headerGridArgs = {data, columns, options}
      return {}
    })
  })

  afterEach(() => {
    gridStub.mockRestore()
    document.body.innerHTML = ''
  })

  const initGradebook = function (uploadedGradebook = defaultUploadedGradebook) {
    gradebook_uploads.init(uploadedGradebook)
  }

  describe('column creation', () => {
    it('creates a pair of columns for each grading period in the grading_periods hash', () => {
      initGradebook()

      const columnIds = mainGridArgs.columns
        .map(column => column.id)
        .filter(id => id.includes('override_score'))

      expect(columnIds).toEqual([
        'override_score_1_conflicting',
        'override_score_1',
        'override_score_2_conflicting',
        'override_score_2',
        'override_score_3_conflicting',
        'override_score_3',
      ])
    })

    it('adds a header for each grading period including the title of the grading period', () => {
      initGradebook()

      const headers = headerGridArgs.columns
        .map(column => column.name)
        .filter(name => name.includes('Override Score'))

      expect(headers).toEqual([
        'Override Score (first GP)',
        'Override Score (second GP)',
        'Override Score (third GP)',
      ])
    })

    it('creates a column for course scores if includes_course_scores is true', () => {
      defaultUploadedGradebook.override_scores.includes_course_scores = true
      defaultUploadedGradebook.override_scores.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_score_course',
      )
      expect(gradingPeriodColumn).toBeTruthy()
    })

    it('adds a header for course scores with the label of plain old "Override Grade"', () => {
      defaultUploadedGradebook.override_scores.includes_course_scores = true
      defaultUploadedGradebook.override_scores.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = headerGridArgs.columns.find(
        column => column.name === 'Override Score',
      )
      expect(gradingPeriodColumn).toBeTruthy()
    })

    it('does not create a column for course scores if includes_course_scores is false', () => {
      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_score_course',
      )
      expect(gradingPeriodColumn).toBeFalsy()
    })

    it('creates a pair of columns for each grading period in the grading_periods hash of override status', () => {
      initGradebook()

      const columnIds = mainGridArgs.columns
        .map(column => column.id)
        .filter(id => id.includes('override_status'))

      expect(columnIds).toEqual([
        'override_status_1_conflicting',
        'override_status_1',
        'override_status_2_conflicting',
        'override_status_2',
        'override_status_3_conflicting',
        'override_status_3',
      ])
    })

    it('adds a header for each grading period including the title of the grading period of override status', () => {
      initGradebook()

      const headers = headerGridArgs.columns
        .map(column => column.name)
        .filter(name => name.includes('Override Status'))

      expect(headers).toEqual([
        'Override Status (first GP)',
        'Override Status (second GP)',
        'Override Status (third GP)',
      ])
    })

    it('creates a column for course status if includes_course_score_status is true', () => {
      defaultUploadedGradebook.override_statuses.includes_course_score_status = true
      defaultUploadedGradebook.override_statuses.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_status_course',
      )
      expect(gradingPeriodColumn).toBeTruthy()
    })

    it('adds a header for course status with the label of plain old "Override Status"', () => {
      defaultUploadedGradebook.override_statuses.includes_course_score_status = true
      defaultUploadedGradebook.override_statuses.grading_periods = []

      initGradebook()

      const gradingPeriodColumn = headerGridArgs.columns.find(
        column => column.name === 'Override Status',
      )
      expect(gradingPeriodColumn).toBeTruthy()
    })

    it('does not create a column for course status if includes_course_score_status is false', () => {
      initGradebook()

      const gradingPeriodColumn = mainGridArgs.columns.find(
        column => column.id === 'override_status_course',
      )
      expect(gradingPeriodColumn).toBeFalsy()
    })
  })

  describe('value population', () => {
    it('populates the grid data with course override scores for each student', () => {
      initGradebook()

      const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
      expect(dataForStudent.override_score_course).toEqual({
        current_score: '50',
        new_score: null,
      })
    })

    it('populates the grid data with grading period override scores for each student', () => {
      initGradebook()

      const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
      expect(dataForStudent.override_score_1).toEqual({
        current_score: '70',
        grading_period_id: '1',
        new_score: '80',
      })
    })

    it('highlights cells if the override score has gone down', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      expect(firstStudentRow.override_score_2_conflicting).toBe('left-highlight')
      expect(firstStudentRow.override_score_2).toBe('right-highlight')
    })

    it('highlights cells if the override score has been removed', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      expect(firstStudentRow.override_score_course_conflicting).toBe('left-highlight')
      expect(firstStudentRow.override_score_course).toBe('right-highlight')
    })

    it('does not highlight cells if the override score has gone up', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      expect(firstStudentRow.override_score_1_conflicting).toBeFalsy()
      expect(firstStudentRow.override_score_1).toBeFalsy()
    })

    it('does not highlight cells if the override score has not changed', () => {
      defaultUploadedGradebook.students[0].override_scores = [
        {
          current_score: '70',
          grading_period_id: '1',
          new_score: '70',
        },
      ]
      defaultUploadedGradebook.students[0].override_statuses = []
      initGradebook()

      expect(gradeReviewRow).toEqual({})
    })

    it('does not highlight cells if the override score is newly added', () => {
      defaultUploadedGradebook.students[0].override_scores = [
        {
          current_score: null,
          grading_period_id: '1',
          new_score: '70',
        },
      ]
      defaultUploadedGradebook.students[0].override_statuses = []
      initGradebook()

      expect(gradeReviewRow).toEqual({})
    })

    it('highlights cells if the override status has been removed', () => {
      initGradebook()

      const firstStudentRow = gradeReviewRow[0]
      expect(firstStudentRow.override_status_3_conflicting).toBe('left-highlight')
      expect(firstStudentRow.override_status_3).toBe('right-highlight')
    })

    it('does not highlight cells if the override status has been newly added', () => {
      defaultUploadedGradebook.students[0].override_scores = []
      defaultUploadedGradebook.students[0].override_statuses = [
        {
          grading_period_id: '1',
          student_id: '1',
          current_grade_status: null,
          new_grade_status: 'CARROT',
        },
      ]
      initGradebook()

      expect(gradeReviewRow).toEqual({})
    })
  })
})
