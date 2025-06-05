/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import PerformanceControls from '../PerformanceControls'
import {RequestDispatch} from '@canvas/network'
import Gradebook from '../Gradebook'
import GradebookApi from '../apis/GradebookApi'
import {createGradebook, setFixtureHtml, defaultGradebookProps} from './GradebookSpecHelper'
import userSettings from '@canvas/user-settings'

// Mock the @canvas/user-settings module
jest.mock('@canvas/user-settings', () => ({
  contextGet: jest.fn(),
  contextRemove: jest.fn(),
  contextSet: jest.fn(),
  get: jest.fn(),
  set: jest.fn(),
}))

// Mock the FlashAlert module
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(),
  showFlashSuccess: jest.fn(),
  showFlashAlert: jest.fn(),
}))

// Define a global beforeEach to set window.ENV for all tests
beforeEach(() => {
  window.ENV = {
    FEATURES: {instui_nav: false},
    current_user_id: '12345', // Add other necessary ENV properties here
    // Add any other properties that your tests might require
  }
})

// Clean up after all tests
afterEach(() => {
  jest.restoreAllMocks()
  delete window.ENV
})

describe('Gradebook#handleViewOptionsUpdated', () => {
  let $fixtures
  let gradebook
  let container1
  let container2
  let oldEnv

  beforeEach(() => {
    // Setup DOM fixtures
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)

    // Initialize containers
    container1 = document.createElement('div')
    container2 = document.createElement('div')
    document.body.appendChild(container1)
    document.body.appendChild(container2)

    // Backup and set window.ENV
    oldEnv = window.ENV
    window.ENV = {
      FEATURES: {instui_nav: false},
      current_user_id: '12345',
      allow_gradebook_uploads: true,
      post_grades_feature: {
        enabled: true,
      },
      GRADEBOOK_OPTIONS: {
        gradebook_is_editable: true,
      },
      enhanced_gradebook_filters: true,
      SETTINGS: {
        show_unpublished_assignments: false,
        suppress_assignments: false,
      },
      view_ungraded_as_zero: false,
    }

    // Initialize PerformanceControls and RequestDispatch
    const performanceControls = new PerformanceControls({
      students_chunk_size: 2, // students per page
    })
    const dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit,
    })

    // Mount and render the Gradebook component
    const component = React.createElement(Gradebook, {
      ...defaultGradebookProps,
      course_settings: {
        allow_final_grade_override: true,
      },
      allow_view_ungraded_as_zero: true,
      context_id: '100',
      currentUserId: '12345',
      gradebookExportUrl: '/api/v1/courses/1/gradebook_csv',
      gradebookImportUrl: '/api/v1/courses/1/gradebook_upload',
      postGradesFeature: {
        enabled: true,
        returnFocusTo: document.body,
        label: 'Post Grades',
        store: {
          getState: () => ({}),
          dispatch: () => {},
        },
      },
      gradebookIsEditable: true,
      contextAllowsGradebookUploads: true,
      getAssignmentOrder: () => [],
      getStudentOrder: () => [],
      setExportManager: () => {},
      updateExportState: () => {},
      publishGradesToSis: {
        isEnabled: true,
        publishToSisUrl: '/api/v1/courses/1/post_grades',
      },
      showStudentFirstLastName: true,
      enhanced_gradebook_filters: true,
      ref: el => {
        gradebook = el
      },
      settings: {
        show_unpublished_assignments: false,
      },
      view_ungraded_as_zero: false,
      performanceControls,
      dispatch,
    })
    ReactDOM.render(component, container2)

    // Simulate received assignment groups
    gradebook.gotAllAssignmentGroups([
      {
        id: '2201',
        position: 1,
        name: 'Assignments',
        assignments: [
          {id: '2301', name: 'assignment1', points_possible: 100, published: true},
          {id: '2302', name: 'assignment2', points_possible: 50, published: true},
          {id: '2303', name: 'unpublished', points_possible: 1500, published: false},
        ],
      },
    ])

    // Mock Gradebook methods
    gradebook.createGrid = jest.fn()
    gradebook.updateGrid = jest.fn()
    gradebook.updateAllTotalColumns = jest.fn()

    // Initialize grid settings
    gradebook.setColumnOrder({sortType: 'due_date', direction: 'ascending'})
    gradebook.gotCustomColumns([])
    gradebook.initGrid()

    // Mock GradebookApi methods
    jest.spyOn(GradebookApi, 'createTeacherNotesColumn').mockResolvedValue({
      data: {
        id: '9999',
        hidden: false,
        name: 'Notes',
        position: 1,
        teacher_notes: true,
      },
    })
    jest.spyOn(GradebookApi, 'saveUserSettings').mockResolvedValue()
    jest.spyOn(GradebookApi, 'updateTeacherNotesColumn').mockResolvedValue()
  })

  afterEach(() => {
    // Restore mocks and clean up DOM
    jest.restoreAllMocks()
    ReactDOM.unmountComponentAtNode(container2)
    container1.remove()
    container2.remove()
    document.body.removeChild($fixtures)
    window.ENV = oldEnv
  })

  const teacherNotesColumn = () =>
    gradebook.gradebookContent.customColumns
      .filter(column => !column.hidden)
      .find(column => column.id === '9999')

  describe('when updating column sort settings', () => {
    test('sorts the grid columns when the API call completes', async () => {
      await gradebook.handleViewOptionsUpdated({
        columnSortSettings: {criterion: 'points', direction: 'ascending'},
      })
      expect(gradebook.gridData.columns.scrollable).toEqual([
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2201',
        'total_grade',
        'total_grade_override',
      ])
    })
  })

  describe('when updating view settings', () => {
    describe('when the notes column does not exist', () => {
      test('calls the createTeacherNotesColumn API function if showNotes is true', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: true})
        expect(GradebookApi.createTeacherNotesColumn).toHaveBeenCalledTimes(1)
        expect(GradebookApi.createTeacherNotesColumn).toHaveBeenCalledWith('100')
      })

      test('does not call createTeacherNotesColumn if showNotes is false', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: false})
        expect(GradebookApi.createTeacherNotesColumn).not.toHaveBeenCalled()
      })

      test('shows the notes column when the API call completes', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: true})
        expect(teacherNotesColumn()).toBeDefined()
      })

      test('does not update the visibility of the notes column if the API call fails', async () => {
        GradebookApi.createTeacherNotesColumn.mockRejectedValue(new Error('NO!'))
        await expect(gradebook.handleViewOptionsUpdated({showNotes: true})).rejects.toThrow('NO!')
        expect(teacherNotesColumn()).toBeUndefined()
      })
    })

    describe('when the notes column already exists', () => {
      beforeEach(() => {
        gradebook.gotCustomColumns([
          {id: '9999', teacher_notes: true, hidden: false, title: 'Notes'},
        ])
      })

      test('calls the updateTeacherNotesColumn API function if showNotes changes', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: false})
        expect(GradebookApi.updateTeacherNotesColumn).toHaveBeenCalledTimes(1)
        expect(GradebookApi.updateTeacherNotesColumn).toHaveBeenCalledWith('100', '9999', {
          hidden: true,
        })
      })

      test('does not call updateTeacherNotesColumn if showNotes has not changed', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: true})
        expect(GradebookApi.updateTeacherNotesColumn).not.toHaveBeenCalled()
      })

      describe('when the API call completes', () => {
        test('shows the notes column if showNotes was set to true', async () => {
          gradebook.hideNotesColumn()
          await gradebook.handleViewOptionsUpdated({showNotes: true})
          expect(teacherNotesColumn()).toBeDefined()
        })

        test('hides the notes column if showNotes was set to false', async () => {
          gradebook.showNotesColumn()
          await gradebook.handleViewOptionsUpdated({showNotes: false})
          expect(teacherNotesColumn()).toBeUndefined()
        })
      })

      test('does not update the visibility of the notes column if the API call fails', async () => {
        GradebookApi.updateTeacherNotesColumn.mockRejectedValue(new Error('NOOOOO'))
        await expect(gradebook.handleViewOptionsUpdated({showNotes: false})).rejects.toThrow(
          'NOOOOO',
        )
        expect(teacherNotesColumn().hidden).toBe(false)
      })
    })

    describe('when updating items stored in user settings', () => {
      const updateParams = (overrides = {}) => ({
        hideAssignmentGroupTotals: false,
        hideTotal: false,
        showUnpublishedAssignments: false,
        showSeparateFirstLastNames: false,
        statusColors: gradebook.state.gridColors,
        viewUngradedAsZero: false,
        ...overrides,
      })

      test('calls the saveUserSettings API function with the changed values', async () => {
        await gradebook.handleViewOptionsUpdated(
          updateParams({
            showUnpublishedAssignments: true,
            statusColors: {...gradebook.state.gridColors, dropped: '#000000'},
            viewUngradedAsZero: true,
          }),
        )

        expect(GradebookApi.saveUserSettings).toHaveBeenCalledTimes(1)
        const [courseId, params] = GradebookApi.saveUserSettings.mock.calls[0]
        expect(courseId).toBe('100')
        expect(params.colors.dropped).toBe('#000000')
        expect(params.show_unpublished_assignments).toBe('true')
        expect(params.view_ungraded_as_zero).toBe('true')
      })

      test('does not call saveUserSettings if no value has changed', async () => {
        await gradebook.handleViewOptionsUpdated(updateParams())
        expect(GradebookApi.saveUserSettings).not.toHaveBeenCalled()
      })

      describe('updating showSeparateFirstLastNames assignments', () => {
        test('shows separate last/first names when showSeparateFirstLastNames is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({showSeparateFirstLastNames: true}))
          expect(gradebook.gridData.columns.frozen).toEqual([
            'student_lastname',
            'student_firstname',
          ])
        })

        test('shows student name when showSeparateFirstLastNames is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(
            updateParams({showSeparateFirstLastNames: false}),
          )
          expect(gradebook.gridData.columns.frozen).toEqual(['student'])
        })

        test('does not update student columns if the request fails', async () => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('no way'))
          await expect(
            gradebook.handleViewOptionsUpdated({showSeparateFirstLastNames: true}),
          ).rejects.toThrow('no way')
          expect(gradebook.gridData.columns.frozen).toEqual(['student'])
        })
      })

      describe('updating hideAssignmentGroupTotals', () => {
        test('hides Assignment Group Total columns when hideAssignmentGroupTotals is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideAssignmentGroupTotals: true}))
          expect(gradebook.gridData.columns.scrollable.includes('assignment_group_2201')).toBe(
            false,
          )
        })

        test('shows Assignment Group Total columns when hideAssignmentGroupTotals is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideAssignmentGroupTotals: false}))
          expect(gradebook.gridData.columns.scrollable.includes('assignment_group_2201')).toBe(true)
        })

        test('does not hide Assignment Group Total columns if the request fails', async () => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('no way'))
          await expect(
            gradebook.handleViewOptionsUpdated({hideAssignmentGroupTotals: true}),
          ).rejects.toThrow('no way')
          expect(gradebook.gridData.columns.scrollable.includes('assignment_group_2201')).toBe(true)
        })
      })

      describe('updating hideTotal', () => {
        test('hides Total column when hideTotal is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: true}))
          expect(gradebook.gridData.columns.scrollable.includes('total')).toBe(false)
        })

        test('shows Total columns when hideTotal is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: false}))
          expect(gradebook.gridData.columns.scrollable.includes('total_grade')).toBe(true)
        })

        test('does not hide Total column if the request fails', async () => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('no way'))
          await expect(gradebook.handleViewOptionsUpdated({hideTotal: true})).rejects.toThrow(
            'no way',
          )
          expect(gradebook.gridData.columns.scrollable.includes('total_grade')).toBe(true)
        })

        test('hides Override column when hideTotal is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: true}))
          expect(gradebook.gridData.columns.scrollable.includes('total_grade_override')).toBe(false)
        })
      })

      describe('updating showing unpublished assignments', () => {
        test('shows unpublished assignments when showUnpublishedAssignments is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({showUnpublishedAssignments: true}))
          expect(gradebook.gridData.columns.scrollable.includes('assignment_2303')).toBe(true)
        })

        test('hides unpublished assignments when showUnpublishedAssignments is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(
            updateParams({showUnpublishedAssignments: false}),
          )
          expect(gradebook.gridData.columns.scrollable.includes('assignment_2303')).toBe(false)
        })

        test('does not update the list of visible assignments if the request fails', async () => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('no way'))
          await expect(
            gradebook.handleViewOptionsUpdated({showUnpublishedAssignments: true}),
          ).rejects.toThrow('no way')
          expect(gradebook.gridData.columns.scrollable.includes('assignment_2303')).toBe(false)
        })
      })

      describe('updating view ungraded as zero', () => {
        test('makes updates to the grid when the request completes', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({viewUngradedAsZero: true}))
          expect(gradebook.updateAllTotalColumns).toHaveBeenCalledTimes(1)
          expect(gradebook.gridDisplaySettings.viewUngradedAsZero).toBe(true)
        })

        test('does not make updates to grid if the request fails', async () => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('STILL NO'))
          await expect(
            gradebook.handleViewOptionsUpdated({viewUngradedAsZero: true}),
          ).rejects.toThrow('STILL NO')
          expect(gradebook.updateAllTotalColumns).not.toHaveBeenCalled()
          expect(gradebook.gridDisplaySettings.viewUngradedAsZero).toBe(false)
        })
      })

      describe('updating status colors', () => {
        test('updates the grid colors when the request completes', async () => {
          const newColors = {...gradebook.state.gridColors, dropped: '#AAAAAA'}

          await gradebook.handleViewOptionsUpdated(updateParams({statusColors: newColors}))
          expect(gradebook.state.gridColors.dropped).toBe('#AAAAAA')
        })

        test('does not update the grid colors if the request fails', async () => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('no :|'))
          const oldColors = {...gradebook.state.gridColors}

          await expect(
            gradebook.handleViewOptionsUpdated({
              statusColors: {dropped: '#AAAAAA'},
            }),
          ).rejects.toThrow('no :|')
          expect(gradebook.state.gridColors).toEqual(oldColors)
        })
      })
    })

    test('does not update the grid until all requests complete', async () => {
      let resolveSettingsRequest

      // Create a promise that can be resolved manually
      GradebookApi.saveUserSettings.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveSettingsRequest = resolve
          }),
      )

      const promise = gradebook.handleViewOptionsUpdated({
        columnSortSettings: {criterion: 'points', direction: 'ascending'},
        showNotes: true,
        showUnpublishedAssignments: true,
      })

      expect(gradebook.updateGrid).not.toHaveBeenCalled()

      // Resolve the promise to simulate API response
      resolveSettingsRequest()
      await promise

      expect(gradebook.updateGrid).toHaveBeenCalled()
    })

    describe('when updates have completed', () => {
      describe('when at least one API call has failed', () => {
        beforeEach(() => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('...'))
          window.ENV = {FEATURES: {instui_nav: false}, current_user_id: '12345'}
        })

        afterEach(() => {
          window.ENV = {FEATURES: {instui_nav: false}, current_user_id: '12345'}
        })

        test.skip('shows a flash error', async () => {
          GradebookApi.createTeacherNotesColumn.mockRejectedValue(new Error('NO!'))
          await expect(
            gradebook.handleViewOptionsUpdated({
              columnSortSettings: {criterion: 'points', direction: 'ascending'},
              showNotes: true,
            }),
          ).rejects.toThrow('NO!')
          expect(FlashAlert.showFlashError).toHaveBeenCalledWith('NO!')
        })

        test.skip('nevertheless updates the grid', async () => {
          GradebookApi.createTeacherNotesColumn.mockRejectedValue(new Error('NO!'))
          await expect(
            gradebook.handleViewOptionsUpdated({
              columnSortSettings: {criterion: 'points', direction: 'ascending'},
              showNotes: true,
            }),
          ).rejects.toThrow('NO!')
          expect(gradebook.updateGrid).toHaveBeenCalled()
        })
      })

      test('updates the grid if all requests succeeded', async () => {
        await gradebook.handleViewOptionsUpdated({
          columnSortSettings: {criterion: 'points', direction: 'ascending'},
          showNotes: true,
          showUnpublishedAssignments: true,
        })
        expect(gradebook.updateGrid).toHaveBeenCalled()
      })
    })
  })
})

describe('Gradebook#toggleShowSeparateFirstLastNames', () => {
  let gradebook
  let $fixtures

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)

    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: jest.fn(),
      },
      settings: {
        allow_separate_first_last_names: 'true',
      },
    })

    jest.spyOn(gradebook, 'saveSettings').mockResolvedValue()
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($fixtures)
    document.body.removeChild($fixtures)
    jest.restoreAllMocks()
  })

  test('toggles showSeparateFirstLastNames to true when false', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = false
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleShowSeparateFirstLastNames()

    expect(gradebook.gridDisplaySettings.showSeparateFirstLastNames).toBe(true)
  })

  test('toggles showSeparateFirstLastNames to false when true', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = true
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleShowSeparateFirstLastNames()

    expect(gradebook.gridDisplaySettings.showSeparateFirstLastNames).toBe(false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = true
    const updateSpy = jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleShowSeparateFirstLastNames()

    expect(updateSpy).toHaveBeenCalledTimes(1)
    expect(gradebook.gridDisplaySettings.showSeparateFirstLastNames).toBe(false)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = false
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleShowSeparateFirstLastNames()

    expect(gradebook.saveSettings).toHaveBeenCalledWith({
      showSeparateFirstLastNames: true,
    })
  })
})

describe('Gradebook#toggleHideAssignmentGroupTotals', () => {
  let gradebook
  let $fixtures

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)

    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: jest.fn(),
      },
    })

    jest.spyOn(gradebook, 'saveSettings').mockResolvedValue()
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($fixtures)
    document.body.removeChild($fixtures)
    jest.restoreAllMocks()
  })

  test('toggles hideAssignmentGroupTotals to true when false', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = false
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideAssignmentGroupTotals()

    expect(gradebook.gridDisplaySettings.hideAssignmentGroupTotals).toBe(true)
  })

  test('toggles hideAssignmentGroupTotals to false when true', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = true
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideAssignmentGroupTotals()

    expect(gradebook.gridDisplaySettings.hideAssignmentGroupTotals).toBe(false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = true
    const updateSpy = jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideAssignmentGroupTotals()
    expect(updateSpy).toHaveBeenCalledTimes(1)
    expect(gradebook.gridDisplaySettings.hideAssignmentGroupTotals).toBe(false)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = false
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleHideAssignmentGroupTotals()

    expect(gradebook.saveSettings).toHaveBeenCalledWith({
      hideAssignmentGroupTotals: true,
    })
  })
})

describe('Gradebook#toggleHideTotal', () => {
  let gradebook
  let $fixtures

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)

    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: jest.fn(),
      },
    })

    jest.spyOn(gradebook, 'saveSettings').mockResolvedValue()
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($fixtures)
    document.body.removeChild($fixtures)
    jest.restoreAllMocks()
  })

  test('toggles hideTotal to true when false', () => {
    gradebook.gridDisplaySettings.hideTotal = false
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideTotal()

    expect(gradebook.gridDisplaySettings.hideTotal).toBe(true)
  })

  test('toggles hideTotal to false when true', () => {
    gradebook.gridDisplaySettings.hideTotal = true
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideTotal()

    expect(gradebook.gridDisplaySettings.hideTotal).toBe(false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.hideTotal = true
    const updateSpy = jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideTotal()
    expect(updateSpy).toHaveBeenCalledTimes(1)
    expect(gradebook.gridDisplaySettings.hideTotal).toBe(false)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.hideTotal = false
    jest.spyOn(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleHideTotal()

    expect(gradebook.saveSettings).toHaveBeenCalledWith({
      hideTotal: true,
    })
  })
})

describe('Gradebook#updateColumnsAndRenderGradebookSettingsModal', () => {
  let gradebook
  let $fixtures

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)

    setFixtureHtml($fixtures)
    gradebook = createGradebook()
    jest.spyOn(gradebook, 'updateColumns').mockImplementation()
    jest.spyOn(gradebook, 'renderGradebookSettingsModal').mockImplementation()
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($fixtures)
    document.body.removeChild($fixtures)
    jest.restoreAllMocks()
  })

  test('calls updateColumns', () => {
    gradebook.updateColumnsAndRenderGradebookSettingsModal()
    expect(gradebook.updateColumns).toHaveBeenCalledTimes(1)
  })

  test('calls renderGradebookSettingsModal', () => {
    gradebook.updateColumnsAndRenderGradebookSettingsModal()
    expect(gradebook.renderGradebookSettingsModal).toHaveBeenCalledTimes(1)
  })
})
