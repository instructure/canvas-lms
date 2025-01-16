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
import gradebook_uploads from '../index'

// Initialize grid args in global scope
let mainGridArgs = {columns: [], data: [], options: {}}
let headerGridArgs = {columns: [], data: [], options: {}}
let mockGrid

// Mock Slick global
global.Slick = {
  Grid: jest.fn((container, data, columns, options) => {
    if (container.is('#gradebook_grid')) {
      mainGridArgs = {data, columns, options}
    } else if (container.is('#gradebook_grid_header')) {
      headerGridArgs = {data, columns, options}
    }
    return mockGrid
  }),
  Editors: {},
}

describe('GradebookUploads', () => {
  let container
  let gradeReviewRow

  const defaultUploadedGradebook = {
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
        override_scores: [
          {
            current_score: '70',
            grading_period_id: '1',
            new_score: '80',
          },
          {
            current_score: '90',
            grading_period_id: '2',
            new_score: '85',
          },
          {
            current_score: '50',
            grading_period_id: 'course',
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
            current_grade_status: 'POTATO',
            new_grade_status: 'POTATO',
          },
          {
            grading_period_id: '3',
            student_id: '1',
            current_grade_status: 'BROCCOLI',
            new_grade_status: null,
          },
        ],
      },
    ],
    warning_messages: {
      prevented_grading_ungradeable_submission: false,
      prevented_new_assignment_creation_in_closed_period: false,
    },
    override_scores: {
      includes_course_scores: false,
      grading_periods: [
        {id: '1', title: 'first GP'},
        {id: '2', title: 'second GP'},
        {id: '3', title: 'third GP'},
      ],
    },
    override_statuses: {
      includes_course_score_status: false,
      grading_periods: [
        {id: '1', title: 'first GP'},
        {id: '2', title: 'second GP'},
        {id: '3', title: 'third GP'},
      ],
    },
  }

  beforeEach(() => {
    container = document.createElement('div')
    container.innerHTML = `
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
    document.body.appendChild(container)
    mainGridArgs = {columns: [], data: [], options: {}}
    headerGridArgs = {columns: [], data: [], options: {}}
    gradeReviewRow = {}

    // Mock grid creation
    mockGrid = {
      invalidateRow: jest.fn(),
      render: jest.fn(),
      setCellCssStyles: jest.fn((_style, rows) => {
        gradeReviewRow = rows
      }),
    }

    $.fn.fillWindowWithMe = jest.fn()
    $.fn.SlickGrid = jest.fn((container, data, columns, options) => {
      if (container.is('#gradebook_grid')) {
        mainGridArgs = {data, columns, options}
      } else if (container.is('#gradebook_grid_header')) {
        headerGridArgs = {data, columns, options}
      }
      return mockGrid
    })
  })

  afterEach(() => {
    container.remove()
    jest.clearAllMocks()
  })

  describe('createGeneralFormatter', () => {
    let formatter

    beforeEach(() => {
      formatter = gradebook_uploads.createGeneralFormatter('foo')
    })

    it('returns expected lookup value', () => {
      const formatted = formatter(null, null, {foo: 'bar'})
      expect(formatted).toBe('bar')
    })

    it('returns empty string when lookup value missing', () => {
      const formatted = formatter(null, null, null)
      expect(formatted).toBe('')
    })

    it('escapes passed-in HTML', () => {
      const formatted = formatter(null, null, {foo: 'bar & <baz>'})
      expect(formatted).toBe('bar &amp; &lt;baz&gt;')
    })
  })

  describe('handleThingsNeedingToBeResolved', () => {
    const initGradebook = (uploadedGradebook = defaultUploadedGradebook) => {
      gradebook_uploads.init(uploadedGradebook)
    }

    describe('column creation', () => {
      it('creates a pair of columns for each grading period', () => {
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

      it('adds headers for each grading period with titles', () => {
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

      it('creates course scores column when includes_course_scores is true', () => {
        const modifiedGradebook = {
          ...defaultUploadedGradebook,
          override_scores: {
            includes_course_scores: true,
            grading_periods: [],
          },
        }
        initGradebook(modifiedGradebook)

        const courseScoreColumn = mainGridArgs.columns.find(
          column => column.id === 'override_score_course',
        )
        expect(courseScoreColumn).toBeTruthy()
      })

      it('does not create course scores column when includes_course_scores is false', () => {
        initGradebook()

        const courseScoreColumn = mainGridArgs.columns.find(
          column => column.id === 'override_score_course',
        )
        expect(courseScoreColumn).toBeFalsy()
      })
    })

    describe('value population', () => {
      it('populates grid data with course override scores', () => {
        const modifiedGradebook = {
          ...defaultUploadedGradebook,
          override_scores: {
            includes_course_scores: true,
            grading_periods: [],
          },
        }
        initGradebook(modifiedGradebook)

        const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
        expect(dataForStudent.override_score_course).toEqual({
          current_score: '50',
          new_score: null,
          grading_period_id: 'course',
        })
      })

      it('populates grid data with grading period override scores', () => {
        initGradebook()

        const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
        expect(dataForStudent.override_score_1).toEqual({
          current_score: '70',
          grading_period_id: '1',
          new_score: '80',
        })
      })

      it('highlights cells when override score decreases', () => {
        initGradebook()

        expect(gradeReviewRow[0].override_score_2_conflicting).toBe('left-highlight')
        expect(gradeReviewRow[0].override_score_2).toBe('right-highlight')
      })

      it('does not highlight cells when override score increases', () => {
        initGradebook()

        expect(gradeReviewRow[0].override_score_1_conflicting).toBeFalsy()
        expect(gradeReviewRow[0].override_score_1).toBeFalsy()
      })
    })

    describe('override status handling', () => {
      it('populates grid data with course override statuses', () => {
        const modifiedGradebook = {
          ...defaultUploadedGradebook,
          override_statuses: {
            includes_course_score_status: true,
            grading_periods: [],
          },
          students: [
            {
              ...defaultUploadedGradebook.students[0],
              override_statuses: [
                {
                  grading_period_id: null,
                  student_id: '1',
                  current_grade_status: 'BROCCOLI',
                  new_grade_status: 'POTATO',
                },
              ],
            },
          ],
        }
        initGradebook(modifiedGradebook)

        const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
        expect(dataForStudent.override_status_course).toEqual({
          current_grade_status: 'BROCCOLI',
          new_grade_status: 'POTATO',
          grading_period_id: null,
          student_id: '1',
        })
      })

      it('populates grid data with grading period override statuses', () => {
        initGradebook()

        const dataForStudent = mainGridArgs.data.find(datum => datum.id === '1')
        expect(dataForStudent.override_status_1).toEqual({
          grading_period_id: '1',
          student_id: '1',
          current_grade_status: 'CARROT',
          new_grade_status: 'POTATO',
        })
      })

      it('highlights cells when override status changes', () => {
        initGradebook()

        expect(gradeReviewRow[0].override_status_1_conflicting).toBe('left-highlight')
        expect(gradeReviewRow[0].override_status_1).toBe('right-highlight')
      })

      it('highlights cells when override status is removed', () => {
        initGradebook()

        expect(gradeReviewRow[0].override_status_3_conflicting).toBe('left-highlight')
        expect(gradeReviewRow[0].override_status_3).toBe('right-highlight')
      })

      it('does not highlight cells when override status is newly added', () => {
        const modifiedGradebook = {
          ...defaultUploadedGradebook,
          students: [
            {
              ...defaultUploadedGradebook.students[0],
              override_scores: [],
              override_statuses: [
                {
                  grading_period_id: '1',
                  student_id: '1',
                  current_grade_status: null,
                  new_grade_status: 'POTATO',
                },
              ],
            },
          ],
        }
        initGradebook(modifiedGradebook)

        expect(gradeReviewRow).toEqual({})
      })

      it('does not highlight cells when override status remains unchanged', () => {
        const modifiedGradebook = {
          ...defaultUploadedGradebook,
          students: [
            {
              ...defaultUploadedGradebook.students[0],
              override_scores: [],
              override_statuses: [
                {
                  grading_period_id: '1',
                  student_id: '1',
                  current_grade_status: 'POTATO',
                  new_grade_status: 'POTATO',
                },
              ],
            },
          ],
        }
        initGradebook(modifiedGradebook)

        expect(gradeReviewRow).toEqual({})
      })

      it('does not highlight cells when only override status case changes', () => {
        const modifiedGradebook = {
          ...defaultUploadedGradebook,
          students: [
            {
              ...defaultUploadedGradebook.students[0],
              override_scores: [],
              override_statuses: [
                {
                  grading_period_id: '1',
                  student_id: '1',
                  current_grade_status: 'POTATO',
                  new_grade_status: 'potato',
                },
              ],
            },
          ],
        }
        initGradebook(modifiedGradebook)

        expect(gradeReviewRow).toEqual({})
      })
    })
  })
})
