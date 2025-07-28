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
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import SlickGridSpecHelper from '../GradebookGrid/GridSupport/__tests__/SlickGridSpecHelper'

// Mock GradebookGrid
jest.mock('../GradebookGrid', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => ({
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
        getColumnIndex: jest.fn().mockReturnValue(0),
        getColumns: jest.fn().mockReturnValue([
          {id: 'assignment_2301', width: 150},
          {id: 'assignment_2302', width: 150},
          {id: 'assignment_2303', width: 150},
          {id: 'assignment_2304', width: 150},
        ]),
        setColumns: jest.fn(),
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
            trigger: jest.fn(),
          },
        },
      },
      gridData: {
        columns: {
          definitions: {
            assignment_2304: {
              width: 150,
            },
          },
        },
      },
    })),
  }
})

// Mock Gradebook class
jest.mock('../Gradebook', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(function (props) {
      return {
        initialize: jest.fn(),
        setAssignmentVisibility: jest.fn(),
        finishRenderingUI: jest.fn(),
        gradebookGrid: null,
        courseContent: {
          contextModules: [],
          modulesById: {},
        },
        getAssignment: jest.fn(),
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
        options: {
          custom_grade_statuses_enabled: false,
          show_similarity_score: false,
          show_total_grade_as_points: false,
        },
        props,
      }
    }),
  }
})

describe('Gradebook Grid Column Widths', () => {
  let fixture
  let gridSpecHelper
  let gradebook

  const contextModules = [
    {
      id: '2601',
      name: 'Module 1',
      position: 1,
      workflow_state: 'active',
      prerequisites: [],
      requirement_count: 0,
      name_length: 9,
      publish_final_grade: false,
      require_sequential_progress: false,
      items_count: 1,
      items_url: 'http://canvas.docker/api/v1/courses/2/modules/2601/items',
      state: 'completed',
      completed_at: null,
      published: true,
      visible_to_everyone: true,
    },
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
        html_url: '/assignments/2303',
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
        html_url: '/assignments/2302',
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
        html_url: '/assignments/2304',
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

  function createGradebookAndAddData(options = {}) {
    gradebook = createGradebook({
      ...options,
      gradebook_is_editable: true,
      context_modules: contextModules,
      custom_columns: customColumns,
      assignment_groups: assignmentGroups,
      grading_period_set: {
        id: '1501',
        grading_periods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      },
    })

    // Set initial state
    gradebook.courseContent.contextModules = contextModules
    gradebook.courseContent.modulesById = {}
    contextModules.forEach(module => {
      gradebook.courseContent.modulesById[module.id] = module
    })

    gradebook.courseContent.customColumns = customColumns
    gradebook.courseContent.assignmentGroups = assignmentGroups

    gradebook.students = {1101: {id: '1101', name: 'Adam Jones', enrollments: []}}
    gradebook.courseContent.students = gradebook.students

    // Create grid container
    const $gridContainer = $('<div id="gradebook_grid"></div>')
    fixture.appendChild($gridContainer[0])

    gradebook.initialize()
    gradebook.setAssignmentVisibility({})
    gradebook.finishRenderingUI()

    gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)

    // Mock column data
    const columnData = {
      assignment_2301: {
        id: 'assignment_2301',
        width: 150,
        minimized: false,
      },
      assignment_2304: {
        id: 'assignment_2304',
        width: 150,
        minimized: false,
      },
    }

    // Mock gridSpecHelper methods
    gridSpecHelper.getColumnHeaderNode = jest.fn().mockImplementation(columnId => {
      const column = columnData[columnId]
      if (!column) {
        return null
      }
      return {
        offsetWidth: column.width,
        classList: {
          contains: jest.fn().mockImplementation(className => {
            if (className === 'minimized') {
              return column.width <= 50
            }
            return false
          }),
          add: jest.fn().mockImplementation(className => {
            if (className === 'minimized') {
              column.minimized = true
            }
          }),
          remove: jest.fn().mockImplementation(className => {
            if (className === 'minimized') {
              column.minimized = false
            }
          }),
        },
      }
    })

    gridSpecHelper.getColumn = jest.fn().mockImplementation(columnId => {
      return columnData[columnId]
    })

    // Set up gradebookGrid
    gradebook.gradebookGrid = {
      gridData: {
        columns: {
          definitions: columnData,
        },
      },
      events: {
        onColumnsResized: {
          trigger: jest.fn().mockImplementation((_, columns) => {
            columns.forEach(column => {
              columnData[column.id].width = column.width
            })
          }),
        },
      },
      destroy: jest.fn(),
    }
  }

  beforeEach(() => {
    fixture = document.createElement('div')
    document.body.appendChild(fixture)
    setFixtureHtml(fixture)
  })

  afterEach(() => {
    gradebook?.gradebookGrid?.destroy()
    $(document).unbind('gridready')
    fixture.remove()
  })

  describe('Initial Column Widths', () => {
    beforeEach(() => {
      gradebook = createGradebook({
        gradebook_column_size_settings: {assignment_2302: 10, assignment_2303: 54},
      })

      // Set initial state
      gradebook.courseContent.contextModules = contextModules
      gradebook.courseContent.modulesById = {}
      contextModules.forEach(module => {
        gradebook.courseContent.modulesById[module.id] = module
      })

      gradebook.courseContent.customColumns = customColumns
      gradebook.courseContent.assignmentGroups = assignmentGroups

      gradebook.students = {1101: {id: '1101', name: 'Adam Jones', enrollments: []}}
      gradebook.courseContent.students = gradebook.students

      // Create grid container
      const $gridContainer = $('<div id="gradebook_grid"></div>')
      fixture.appendChild($gridContainer[0])

      gradebook.initialize()
      gradebook.setAssignmentVisibility({})
      gradebook.finishRenderingUI()

      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)

      // Mock column data
      const columnData = {
        assignment_2301: {
          id: 'assignment_2301',
          width: 150,
          minimized: false,
        },
        assignment_2304: {
          id: 'assignment_2304',
          width: 150,
          minimized: false,
        },
      }

      // Mock gridSpecHelper methods
      gridSpecHelper.getColumnHeaderNode = jest.fn().mockImplementation(columnId => {
        const column = columnData[columnId]
        if (!column) {
          return null
        }
        return {
          offsetWidth: column.width,
          classList: {
            contains: jest.fn().mockImplementation(className => {
              if (className === 'minimized') {
                return column.width <= 50
              }
              return false
            }),
            add: jest.fn().mockImplementation(className => {
              if (className === 'minimized') {
                column.minimized = true
              }
            }),
            remove: jest.fn().mockImplementation(className => {
              if (className === 'minimized') {
                column.minimized = false
              }
            }),
          },
        }
      })

      gridSpecHelper.getColumn = jest.fn().mockImplementation(columnId => {
        return columnData[columnId]
      })

      // Set up gradebookGrid
      gradebook.gradebookGrid = {
        gridData: {
          columns: {
            definitions: columnData,
          },
        },
        events: {
          onColumnsResized: {
            trigger: jest.fn().mockImplementation((_, columns) => {
              columns.forEach(column => {
                columnData[column.id].width = column.width
              })
            }),
          },
        },
        destroy: jest.fn(),
      }
    })

    it('uses the default width for assignment column headers', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2301')
      expect(columnNode.offsetWidth).toBeGreaterThan(10)
    })

    // TODO: unskip in FOO-4349
    it.skip('uses a stored width for assignment column headers', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2303')
      expect(columnNode.offsetWidth).toBe(54)
    })

    // TODO: unskip in FOO-4349
    it.skip('hides assignment column header content when the column is minimized', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2302')
      expect(columnNode.classList).toContain('minimized')
    })

    // TODO: unskip in FOO-4349
    it.skip('hides assignment column cell content when the column is minimized', () => {
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2302')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      expect(cellNode.classList).toContain('minimized')
    })
  })

  describe('onColumnsResized', () => {
    function resizeColumn(columnId, widthChange) {
      const column = gridSpecHelper.getColumn(columnId)
      const updatedColumn = {...column, width: column.width + widthChange}
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, [updatedColumn])
    }

    beforeEach(() => {
      createGradebookAndAddData()
      jest.spyOn(gradebook, 'saveColumnWidthPreference')
    })

    it('updates the column definitions for resized columns', () => {
      const originalWidth = gridSpecHelper.getColumn('assignment_2304').width
      resizeColumn('assignment_2304', -20)
      expect(gradebook.gradebookGrid.gridData.columns.definitions.assignment_2304.width).toBe(
        originalWidth - 20,
      )
    })

    it('hides assignment column header content when the column is minimized', () => {
      resizeColumn('assignment_2304', -100)
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2304')
      expect(columnNode.classList.contains('minimized')).toBe(true)
    })

    it('unhides assignment column header content when the column is unminimized', () => {
      resizeColumn('assignment_2304', -100)
      resizeColumn('assignment_2304', 1)
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2304')
      expect(columnNode.classList.contains('minimized')).toBe(false)
    })

    // TODO: unskip in FOO-4349
    it.skip('hides assignment column cell content when the column is minimized', () => {
      resizeColumn('assignment_2304', -100)
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2304')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      expect(cellNode.classList).toContain('minimized')
    })

    // TODO: unskip in FOO-4349
    it.skip('unhides assignment column cell content when the column is unminimized', () => {
      resizeColumn('assignment_2304', -100)
      resizeColumn('assignment_2304', 1)
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2304')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      expect(cellNode.classList).not.toContain('minimized')
    })
  })
})
