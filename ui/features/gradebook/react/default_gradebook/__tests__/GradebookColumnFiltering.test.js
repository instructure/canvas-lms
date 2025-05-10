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

import 'jquery-migrate'
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import SlickGridSpecHelper from '../GradebookGrid/GridSupport/__tests__/SlickGridSpecHelper'

// Mock GradebookGrid
jest.mock('../GradebookGrid', () => {
  let columns = [
    {id: 'assignment_2302'}, // Quizzes (position 1)
    {id: 'assignment_2304'}, // Quizzes (position 1)
    {id: 'assignment_2301'}, // Homework (position 2)
    {id: 'assignment_2303'}, // Homework (position 2)
  ]

  const gridInstance = {
    initialize: jest.fn(),
    destroy: jest.fn(),
    events: {
      onColumnsReordered: {
        subscribe: jest.fn(),
        trigger: jest.fn(),
      },
      onColumnsResized: {
        subscribe: jest.fn(),
        trigger: jest.fn(),
      },
    },
    grid: {
      getColumns: jest.fn().mockImplementation(() => columns),
      setColumns: jest.fn().mockImplementation(newColumns => {
        columns = newColumns
      }),
      invalidate: jest.fn(),
      render: jest.fn(),
    },
    gridSupport: {
      events: {
        onColumnsResized: {
          subscribe: jest.fn(),
        },
      },
    },
  }

  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => gridInstance),
  }
})

// Mock Gradebook class
jest.mock('../Gradebook', () => {
  const contextModules = {
    2601: {id: '2601', position: 3, name: 'Final Module'},
    2602: {id: '2602', position: 2, name: 'Second Module'},
    2603: {id: '2603', position: 1, name: 'First Module'},
  }

  const assignments = {
    2301: {
      id: '2301',
      name: 'Math Assignment',
      module_ids: ['2601'],
      module_positions: [1],
      assignment_group_id: '2201',
      published: true,
      submission_types: ['attendance'],
    },
    2302: {
      id: '2302',
      name: 'Math Quiz',
      module_ids: ['2602'],
      module_positions: [1],
      assignment_group_id: '2202',
      published: true,
      submission_types: ['online_quiz'],
    },
    2303: {
      id: '2303',
      name: 'English Assignment',
      module_ids: ['2601'],
      module_positions: [2],
      assignment_group_id: '2201',
      published: false,
      submission_types: ['attendance'],
    },
    2304: {
      id: '2304',
      name: 'English Quiz',
      module_ids: ['2603'],
      module_positions: [1],
      assignment_group_id: '2202',
      published: false,
      submission_types: ['online_quiz'],
    },
  }

  const assignmentGroups = {
    2201: {id: '2201', position: 2, name: 'Homework'},
    2202: {id: '2202', position: 1, name: 'Quizzes'},
  }

  return {
    __esModule: true,
    default: jest.fn().mockImplementation(function (props) {
      const instance = {
        initialize: jest.fn(),
        destroy: jest.fn(),
        setAssignmentVisibility: jest.fn(),
        finishRenderingUI: jest.fn(),
        gradebookGrid: null,
        courseContent: {
          contextModules: [],
          modulesById: contextModules,
          assignments,
          assignmentGroups,
        },
        getAssignment: jest
          .fn()
          .mockImplementation(id => assignments[id.replace('assignment_', '')]),
        getAssignmentGroup: jest.fn().mockImplementation(id => assignmentGroups[id]),
        getEnterGradesAsSetting: jest.fn(),
        getAssignmentGradingScheme: jest.fn(),
        getPendingGradeInfo: jest.fn(),
        student: jest.fn(),
        submissionStateMap: {
          getSubmissionState: jest.fn(),
        },
        getTotalPointsPossible: jest.fn(),
        weightedGrades: jest.fn(),
        getCourseGradingScheme: jest.fn(),
        listInvalidAssignmentGroups: jest.fn(),
        listHiddenAssignments: jest.fn(),
        bindGridEvents: jest.fn(),
        saveColumnWidthPreference: jest.fn(),
        updateStudentIds: jest.fn(),
        updateGradingPeriodAssignments: jest.fn(),
        updateContextModules: jest.fn(),
        gotCustomColumns: jest.fn(),
        updateAssignmentGroups: jest.fn(),
        toggleUnpublishedAssignments: jest.fn().mockImplementation(function (show) {
          const columns = instance.gradebookGrid.grid.getColumns()
          const filteredColumns = show
            ? columns
            : columns.filter(column => {
                const assignment = assignments[column.id.replace('assignment_', '')]
                return assignment.published
              })
          instance.gradebookGrid.grid.setColumns(filteredColumns)
        }),
        toggleOnlyAttendanceAssignments: jest.fn().mockImplementation(function (show) {
          const columns = instance.gradebookGrid.grid.getColumns()
          const filteredColumns = show
            ? columns.filter(column => {
                const assignment = assignments[column.id.replace('assignment_', '')]
                return assignment.submission_types[0] === 'attendance'
              })
            : columns.filter(column => {
                const assignment = assignments[column.id.replace('assignment_', '')]
                return assignment.submission_types[0] !== 'attendance'
              })
          instance.gradebookGrid.grid.setColumns(filteredColumns)
        }),
        updateCurrentAssignmentGroup: jest.fn().mockImplementation(function (groupIds) {
          const columns = instance.gradebookGrid.grid.getColumns()
          const filteredColumns = groupIds
            ? columns.filter(column => {
                const assignment = assignments[column.id.replace('assignment_', '')]
                return groupIds.includes(assignment.assignment_group_id)
              })
            : columns
          instance.gradebookGrid.grid.setColumns(filteredColumns)
        }),
        updateCurrentModule: jest.fn().mockImplementation(function (moduleIds) {
          const columns = instance.gradebookGrid.grid.getColumns()
          const filteredColumns = moduleIds
            ? columns.filter(column => {
                const assignment = assignments[column.id.replace('assignment_', '')]
                return assignment.module_ids.some(id => moduleIds.includes(id))
              })
            : columns
          instance.gradebookGrid.grid.setColumns(filteredColumns)
        }),
        updateCurrentGradingPeriod: jest.fn().mockImplementation(function (gradingPeriodId) {
          const columns = instance.gradebookGrid.grid.getColumns()
          const filteredColumns = gradingPeriodId
            ? columns.filter(column => {
                const assignmentId = column.id.replace('assignment_', '')
                return instance.courseContent.gradingPeriodAssignments[gradingPeriodId].includes(
                  assignmentId,
                )
              })
            : columns
          instance.gradebookGrid.grid.setColumns(filteredColumns)
        }),
        options: {
          custom_grade_statuses_enabled: false,
          show_similarity_score: false,
          show_total_grade_as_points: false,
        },
        props,
      }
      return instance
    }),
  }
})

describe('Gradebook Grid Column Filtering', () => {
  let fixture
  let gradebook

  function createGradebookAndAddData(options = {}) {
    gradebook = createGradebook(options)
    const GradebookGrid = require('../GradebookGrid').default
    gradebook.gradebookGrid = new GradebookGrid()
    gradebook.finishRenderingUI()
    new SlickGridSpecHelper(gradebook.gradebookGrid)
  }

  beforeEach(() => {
    fixture = document.createElement('div')
    document.body.appendChild(fixture)
    setFixtureHtml(fixture)

    process.env.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: true}
  })

  afterEach(() => {
    gradebook?.destroy()
    fixture.remove()
    jest.resetModules()
    jest.clearAllMocks()
  })

  describe('when filtering by unpublished assignments', () => {
    beforeEach(() => {
      const assignments = require('../Gradebook').default().courseContent.assignments
      assignments[2303].published = false
      assignments[2304].published = false
      createGradebookAndAddData()
    })

    it('shows unpublished assignments when filter is on', () => {
      gradebook.toggleUnpublishedAssignments(true)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).toContain('assignment_2304')
    })

    it('hides unpublished assignments when filter is off', () => {
      gradebook.toggleUnpublishedAssignments(false)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).not.toContain('assignment_2303')
      expect(columnIds).not.toContain('assignment_2304')
    })
  })

  describe('when filtering by attendance assignments', () => {
    beforeEach(() => {
      createGradebookAndAddData()
    })

    it('shows only attendance assignments when filter is on', () => {
      gradebook.toggleOnlyAttendanceAssignments(true)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).not.toContain('assignment_2302')
      expect(columnIds).not.toContain('assignment_2304')
    })

    it('shows only non-attendance assignments when filter is off', () => {
      gradebook.toggleOnlyAttendanceAssignments(false)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).not.toContain('assignment_2301')
      expect(columnIds).not.toContain('assignment_2303')
      expect(columnIds).toContain('assignment_2302')
      expect(columnIds).toContain('assignment_2304')
    })
  })

  describe('when filtering by assignment groups', () => {
    beforeEach(() => {
      createGradebookAndAddData()
    })

    it('shows assignments from selected groups', () => {
      gradebook.updateCurrentAssignmentGroup(['2201'])
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).not.toContain('assignment_2302')
      expect(columnIds).not.toContain('assignment_2304')
    })

    it('shows all assignments when no group is selected', () => {
      gradebook.updateCurrentAssignmentGroup(null)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2302')
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).toContain('assignment_2304')
    })
  })

  describe('when filtering by modules', () => {
    beforeEach(() => {
      createGradebookAndAddData()
    })

    it('shows assignments from selected modules', () => {
      gradebook.updateCurrentModule(['2601'])
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).not.toContain('assignment_2302')
      expect(columnIds).not.toContain('assignment_2304')
    })

    it('shows all assignments when no module is selected', () => {
      gradebook.updateCurrentModule(null)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2302')
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).toContain('assignment_2304')
    })
  })

  describe('when filtering by grading periods', () => {
    beforeEach(() => {
      createGradebookAndAddData({
        grading_period_set: {
          id: '1501',
          grading_periods: [
            {id: '1401', title: 'GP1'},
            {id: '1402', title: 'GP2'},
          ],
        },
      })
      gradebook.courseContent.gradingPeriodAssignments = {
        1401: ['2301', '2304'],
        1402: ['2302', '2303'],
      }
    })

    it('shows assignments from selected grading period', () => {
      gradebook.updateCurrentGradingPeriod('1401')
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2304')
      expect(columnIds).not.toContain('assignment_2302')
      expect(columnIds).not.toContain('assignment_2303')
    })

    it('shows all assignments when no grading period is selected', () => {
      gradebook.updateCurrentGradingPeriod(null)
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const columnIds = columns.map(column => column.id)
      expect(columnIds).toContain('assignment_2301')
      expect(columnIds).toContain('assignment_2302')
      expect(columnIds).toContain('assignment_2303')
      expect(columnIds).toContain('assignment_2304')
    })
  })
})
