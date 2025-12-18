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
vi.mock('../GradebookGrid', () => {
  return {
    __esModule: true,
    default: vi.fn().mockImplementation(() => ({
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
        getColumnIndex: vi.fn().mockReturnValue(0),
        getColumns: vi.fn().mockReturnValue([
          {id: 'assignment_2301', width: 150},
          {id: 'assignment_2302', width: 150},
          {id: 'assignment_2303', width: 150},
          {id: 'assignment_2304', width: 150},
        ]),
        setColumns: vi.fn(),
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
            trigger: vi.fn(),
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
vi.mock('../Gradebook', () => {
  return {
    __esModule: true,
    default: vi.fn().mockImplementation(function (props) {
      return {
        initialize: vi.fn(),
        setAssignmentVisibility: vi.fn(),
        finishRenderingUI: vi.fn(),
        gradebookGrid: null,
        courseContent: {
          contextModules: [],
          modulesById: {},
        },
        getAssignment: vi.fn(),
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
    gridSpecHelper.getColumnHeaderNode = vi.fn().mockImplementation(columnId => {
      const column = columnData[columnId]
      if (!column) {
        return null
      }
      return {
        offsetWidth: column.width,
        classList: {
          contains: vi.fn().mockImplementation(className => {
            if (className === 'minimized') {
              return column.width <= 50
            }
            return false
          }),
          add: vi.fn().mockImplementation(className => {
            if (className === 'minimized') {
              column.minimized = true
            }
          }),
          remove: vi.fn().mockImplementation(className => {
            if (className === 'minimized') {
              column.minimized = false
            }
          }),
        },
      }
    })

    gridSpecHelper.getColumn = vi.fn().mockImplementation(columnId => {
      return columnData[columnId]
    })

    gridSpecHelper.listColumnIds = vi.fn().mockReturnValue([
      'assignment_2301',
      'assignment_2304',
    ])

    // Set up gradebookGrid
    gradebook.gradebookGrid = {
      gridData: {
        columns: {
          definitions: columnData,
        },
      },
      grid: {
        getCellNode: vi.fn().mockImplementation((row, columnIndex) => {
          const columnIds = gridSpecHelper.listColumnIds()
          const columnId = columnIds[columnIndex]
          const column = columnData[columnId]
          if (!column) {
            return null
          }
          return {
            classList: {
              contains: vi.fn().mockImplementation(className => {
                if (className === 'minimized') {
                  return column.width <= 50
                }
                return false
              }),
            },
          }
        }),
      },
      events: {
        onColumnsResized: {
          trigger: vi.fn().mockImplementation((_, columns) => {
            columns.forEach(column => {
              columnData[column.id].width = column.width
            })
          }),
        },
      },
      destroy: vi.fn(),
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
        assignment_2302: {
          id: 'assignment_2302',
          width: 10,
          minimized: true,
        },
        assignment_2303: {
          id: 'assignment_2303',
          width: 54,
          minimized: false,
        },
        assignment_2304: {
          id: 'assignment_2304',
          width: 150,
          minimized: false,
        },
      }

      // Mock gridSpecHelper methods
      gridSpecHelper.getColumnHeaderNode = vi.fn().mockImplementation(columnId => {
        const column = columnData[columnId]
        if (!column) {
          return null
        }
        return {
          offsetWidth: column.width,
          classList: {
            contains: vi.fn().mockImplementation(className => {
              if (className === 'minimized') {
                return column.width <= 50
              }
              return false
            }),
            add: vi.fn().mockImplementation(className => {
              if (className === 'minimized') {
                column.minimized = true
              }
            }),
            remove: vi.fn().mockImplementation(className => {
              if (className === 'minimized') {
                column.minimized = false
              }
            }),
          },
        }
      })

      gridSpecHelper.getColumn = vi.fn().mockImplementation(columnId => {
        return columnData[columnId]
      })

      gridSpecHelper.listColumnIds = vi.fn().mockReturnValue([
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
      ])

      // Set up gradebookGrid
      gradebook.gradebookGrid = {
        gridData: {
          columns: {
            definitions: columnData,
          },
        },
        grid: {
          getCellNode: vi.fn().mockImplementation((row, columnIndex) => {
            const columnIds = gridSpecHelper.listColumnIds()
            const columnId = columnIds[columnIndex]
            const column = columnData[columnId]
            if (!column) {
              return null
            }
            return {
              classList: {
                contains: vi.fn().mockImplementation(className => {
                  if (className === 'minimized') {
                    return column.width <= 50
                  }
                  return false
                }),
              },
            }
          }),
        },
        events: {
          onColumnsResized: {
            trigger: vi.fn().mockImplementation((_, columns) => {
              columns.forEach(column => {
                columnData[column.id].width = column.width
              })
            }),
          },
        },
        destroy: vi.fn(),
      }
    })

    it('uses the default width for assignment column headers', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2301')
      expect(columnNode.offsetWidth).toBeGreaterThan(10)
    })

    it('uses a stored width for assignment column headers', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2303')
      expect(columnNode.offsetWidth).toBe(54)
    })

    it('hides assignment column header content when the column is minimized', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2302')
      expect(columnNode.classList.contains('minimized')).toBe(true)
    })

    it('hides assignment column cell content when the column is minimized', () => {
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2302')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      expect(cellNode.classList.contains('minimized')).toBe(true)
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
      vi.spyOn(gradebook, 'saveColumnWidthPreference')
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

    it('hides assignment column cell content when the column is minimized', () => {
      resizeColumn('assignment_2304', -100)
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2304')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      expect(cellNode.classList.contains('minimized')).toBe(true)
    })

    it('unhides assignment column cell content when the column is unminimized', () => {
      resizeColumn('assignment_2304', -100)
      resizeColumn('assignment_2304', 1)
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2304')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      expect(cellNode.classList.contains('minimized')).toBe(false)
    })
  })
})
