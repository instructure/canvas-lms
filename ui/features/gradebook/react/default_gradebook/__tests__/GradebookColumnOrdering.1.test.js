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
vi.mock('../GradebookGrid', () => {
  let columns = [
    {id: 'assignment_2302'}, // Quizzes (position 1)
    {id: 'assignment_2304'}, // Quizzes (position 1)
    {id: 'assignment_2301'}, // Homework (position 2)
    {id: 'assignment_2303'}, // Homework (position 2)
  ]

  const gridInstance = {
    initialize: vi.fn(),
    destroy: vi.fn(),
    events: {
      onColumnsReordered: {
        subscribe: vi.fn(),
        trigger: vi.fn(),
      },
      onColumnsResized: {
        subscribe: vi.fn(),
        trigger: vi.fn(),
      },
    },
    grid: {
      getColumns: vi.fn().mockImplementation(() => columns),
      setColumns: vi.fn().mockImplementation(newColumns => {
        columns = newColumns
      }),
      invalidate: vi.fn(),
      render: vi.fn(),
      getHeaderRow: vi.fn().mockReturnValue({
        querySelector: vi.fn().mockReturnValue({
          offsetWidth: 150,
          classList: {
            contains: vi.fn().mockReturnValue(false),
            add: vi.fn(),
            remove: vi.fn(),
          },
        }),
      }),
      getCellNode: vi.fn().mockReturnValue({
        offsetWidth: 150,
        classList: {
          contains: vi.fn().mockReturnValue(false),
          add: vi.fn(),
          remove: vi.fn(),
        },
      }),
    },
    gridSupport: {
      events: {
        onColumnsResized: {
          subscribe: vi.fn(),
        },
      },
    },
  }

  return {
    __esModule: true,
    default: vi.fn().mockImplementation(() => gridInstance),
  }
})

// Mock Gradebook class
vi.mock('../Gradebook', () => {
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
    default: vi.fn().mockImplementation(function (props) {
      const instance = {
        initialize: vi.fn(),
        destroy: vi.fn(),
        setAssignmentVisibility: vi.fn(),
        finishRenderingUI: vi.fn(),
        gradebookGrid: null,
        courseContent: {
          contextModules: [],
          modulesById: contextModules,
          assignments,
          assignmentGroups,
        },
        getAssignment: vi
          .fn()
          .mockImplementation(id => assignments[id.replace('assignment_', '')]),
        getAssignmentGroup: vi.fn().mockImplementation(id => assignmentGroups[id]),
        getEnterGradesAsSetting: vi.fn(),
        getAssignmentGradingScheme: vi.fn(),
        getPendingGradeInfo: vi.fn(),
        student: vi.fn(),
        submissionStateMap: {
          getSubmissionState: vi.fn(),
        },
        getTotalPointsPossible: vi.fn(),
        weightedGrades: vi.fn(),
        getCourseGradingScheme: vi.fn(),
        listInvalidAssignmentGroups: vi.fn(),
        listHiddenAssignments: vi.fn(),
        bindGridEvents: vi.fn(),
        saveColumnWidthPreference: vi.fn(),
        updateStudentIds: vi.fn(),
        updateGradingPeriodAssignments: vi.fn(),
        updateContextModules: vi.fn(),
        gotCustomColumns: vi.fn(),
        updateAssignmentGroups: vi.fn(),
        arrangeColumnsBy: vi.fn().mockImplementation(function ({sortType, direction}) {
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

describe.skip('Gradebook Grid Column Ordering', () => {
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

  describe('when initializing the grid', () => {
    it('defaults assignment column order to assignment group positions when setting is not set', () => {
      createGradebookAndAddData()
      const expectedOrder = [
        'assignment_2302',
        'assignment_2304',
        'assignment_2301',
        'assignment_2303',
      ]
      const columns = gradebook.gradebookGrid.grid.getColumns()
      const actualOrder = columns.map(column => column.id)
      expect(actualOrder).toEqual(expectedOrder)
    })
  })
})
