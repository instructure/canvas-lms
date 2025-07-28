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
      getHeaderRow: jest.fn().mockReturnValue({
        querySelector: jest.fn().mockReturnValue({
          offsetWidth: 150,
          classList: {
            contains: jest.fn().mockReturnValue(false),
            add: jest.fn(),
            remove: jest.fn(),
          },
        }),
      }),
      getCellNode: jest.fn().mockReturnValue({
        offsetWidth: 150,
        classList: {
          contains: jest.fn().mockReturnValue(false),
          add: jest.fn(),
          remove: jest.fn(),
        },
      }),
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
    },
    2302: {
      id: '2302',
      name: 'Math Quiz',
      module_ids: ['2602'],
      module_positions: [1],
      assignment_group_id: '2202',
    },
    2303: {
      id: '2303',
      name: 'English Assignment',
      module_ids: ['2601'],
      module_positions: [2],
      assignment_group_id: '2201',
    },
    2304: {
      id: '2304',
      name: 'English Quiz',
      module_ids: ['2603'],
      module_positions: [1],
      assignment_group_id: '2202',
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
        arrangeColumnsBy: jest.fn().mockImplementation(function ({sortType, direction}) {
          const columns = instance.gradebookGrid.grid.getColumns()
          let sortedColumns

          if (sortType === 'name') {
            sortedColumns = [...columns].sort((a, b) => {
              const assignmentA = assignments[a.id.replace('assignment_', '')]
              const assignmentB = assignments[b.id.replace('assignment_', '')]
              return assignmentA.name.localeCompare(assignmentB.name)
            })
          } else if (sortType === 'module_position') {
            sortedColumns = [...columns].sort((a, b) => {
              const assignmentA = assignments[a.id.replace('assignment_', '')]
              const assignmentB = assignments[b.id.replace('assignment_', '')]
              const moduleA = contextModules[assignmentA.module_ids[0]]
              const moduleB = contextModules[assignmentB.module_ids[0]]
              const directionMultiplier = direction === 'ascending' ? 1 : -1
              return (moduleA.position - moduleB.position) * directionMultiplier
            })
          } else {
            // Default to assignment group order
            sortedColumns = [...columns].sort((a, b) => {
              const assignmentA = assignments[a.id.replace('assignment_', '')]
              const assignmentB = assignments[b.id.replace('assignment_', '')]
              const groupA = assignmentGroups[assignmentA.assignment_group_id]
              const groupB = assignmentGroups[assignmentB.assignment_group_id]
              return groupA.position - groupB.position
            })
          }

          instance.gradebookGrid.grid.setColumns(sortedColumns)
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

describe('Gradebook Grid Column Ordering', () => {
  let fixture
  let gradebook

  const contextModules = [
    {id: '2601', position: 3, name: 'Final Module'},
    {id: '2602', position: 2, name: 'Second Module'},
    {id: '2603', position: 1, name: 'First Module'},
  ]

  const customColumns = [
    {id: '2401', teacher_notes: true, title: 'Notes'},
    {id: '2402', teacher_notes: false, title: 'Other Notes'},
  ]

  const assignments = {
    homework: [
      {
        id: '2301',
        assignment_group_id: '2201',
        course_id: '1201',
        due_at: '2015-05-04T12:00:00Z',
        html_url: '/assignments/2301',
        module_ids: ['2601'],
        module_positions: [1],
        muted: false,
        name: 'Math Assignment',
        omit_from_final_grade: false,
        points_possible: null,
        position: 1,
        published: true,
        submission_types: ['online_text_entry'],
        visible_to_everyone: true,
      },
      {
        id: '2303',
        assignment_group_id: '2201',
        course_id: '1201',
        due_at: '2015-06-04T12:00:00Z',
        html_url: '/assignments/2302',
        module_ids: ['2601'],
        module_positions: [2],
        muted: false,
        name: 'English Assignment',
        omit_from_final_grade: false,
        points_possible: 15,
        position: 2,
        published: true,
        submission_types: ['online_text_entry'],
        visible_to_everyone: true,
      },
    ],
    quizzes: [
      {
        id: '2302',
        assignment_group_id: '2202',
        course_id: '1201',
        due_at: '2015-05-05T12:00:00Z',
        html_url: '/assignments/2301',
        module_ids: ['2602'],
        module_positions: [1],
        muted: false,
        name: 'Math Quiz',
        omit_from_final_grade: false,
        points_possible: 10,
        position: 1,
        published: true,
        submission_types: ['online_quiz'],
        visible_to_everyone: true,
      },
      {
        id: '2304',
        assignment_group_id: '2202',
        course_id: '1201',
        due_at: '2015-05-11T12:00:00Z',
        html_url: '/assignments/2302',
        module_ids: ['2603'],
        module_positions: [1],
        muted: false,
        name: 'English Quiz',
        omit_from_final_grade: false,
        points_possible: 20,
        position: 2,
        published: true,
        submission_types: ['online_quiz'],
        visible_to_everyone: true,
      },
    ],
  }

  const assignmentGroups = [
    {id: '2201', position: 2, name: 'Homework', assignments: assignments.homework},
    {id: '2202', position: 1, name: 'Quizzes', assignments: assignments.quizzes},
  ]

  function addStudentIds() {
    gradebook.updateStudentIds(['1101'])
  }

  function addGradingPeriodAssignments() {
    gradebook.updateGradingPeriodAssignments({1401: ['2301'], 1402: ['2302']})
  }

  function addContextModules() {
    gradebook.updateContextModules(contextModules)
  }

  function addCustomColumns() {
    gradebook.gotCustomColumns(customColumns)
  }

  function addAssignmentGroups() {
    gradebook.updateAssignmentGroups(assignmentGroups)
  }

  function addGridData() {
    addStudentIds()
    addContextModules()
    addCustomColumns()
    addAssignmentGroups()
    addGradingPeriodAssignments()
    gradebook.finishRenderingUI()
  }

  function arrangeColumnsBy(sortType, direction) {
    gradebook.arrangeColumnsBy({sortType, direction})
  }

  function createGradebookAndAddData(options = {}) {
    gradebook = createGradebook(options)
    const GradebookGrid = require('../GradebookGrid').default
    gradebook.gradebookGrid = new GradebookGrid()
    addGridData()
    new SlickGridSpecHelper(gradebook.gradebookGrid)
  }

  beforeEach(() => {
    fixture = document.createElement('div')
    document.body.appendChild(fixture)
    setFixtureHtml(fixture)
  })

  afterEach(() => {
    gradebook?.destroy()
    fixture.remove()
  })

  describe('when sorting by name', () => {
    it('sorts assignment columns by assignment name', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('name', 'ascending')
      const expectedOrder = [
        'assignment_2303', // English Assignment
        'assignment_2304', // English Quiz
        'assignment_2301', // Math Assignment
        'assignment_2302', // Math Quiz
      ]
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const actualOrder = columns.map(column => column.id)
      expect(actualOrder).toEqual(expectedOrder)
    })
  })
})
