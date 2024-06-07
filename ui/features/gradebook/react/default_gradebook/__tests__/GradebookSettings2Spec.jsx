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

const performance_controls = {
  students_chunk_size: 2, // students per page,
}
const $fixtures = document.getElementById('fixtures')

let oldEnv

QUnit.module('Gradebook#handleViewOptionsUpdated', hooks => {
  let gradebook
  let container1
  let container2

  hooks.beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {FEATURES: {instui_nav: false}}
    const performanceControls = new PerformanceControls(performance_controls)
    const dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit,
    })

    // We need to actually mount and render the Gradebook component here to
    // ensure that grid colors (which use setState) are properly updated
    container1 = document.body.appendChild(document.createElement('div'))
    container2 = document.body.appendChild(document.createElement('div'))
    const component = React.createElement(Gradebook, {
      ...defaultGradebookProps,
      course_settings: {
        allow_final_grade_override: true,
      },
      allow_view_ungraded_as_zero: true,
      context_id: '100',
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

    sinon.stub(gradebook, 'createGrid')
    sinon.stub(gradebook, 'updateGrid')
    sinon.stub(gradebook, 'updateAllTotalColumns')

    gradebook.setColumnOrder({sortType: 'due_date', direction: 'ascending'})
    gradebook.gotCustomColumns([])
    gradebook.initGrid()

    sinon.stub(GradebookApi, 'createTeacherNotesColumn').resolves({
      data: {
        id: '9999',
        hidden: false,
        name: 'Notes',
        position: 1,
        teacher_notes: true,
      },
    })
    sinon.stub(GradebookApi, 'saveUserSettings').resolves()
    sinon.stub(GradebookApi, 'updateTeacherNotesColumn').resolves()

    sinon.stub(FlashAlert, 'showFlashError')
    setFixtureHtml(container1)
  })

  hooks.afterEach(() => {
    FlashAlert.showFlashError.restore()

    GradebookApi.updateTeacherNotesColumn.restore()
    GradebookApi.saveUserSettings.restore()
    GradebookApi.createTeacherNotesColumn.restore()

    ReactDOM.unmountComponentAtNode(container2)
    container1.remove()

    window.ENV = oldEnv
  })

  const teacherNotesColumn = () =>
    gradebook.gradebookContent.customColumns
      .filter(column => !column.hidden)
      .find(column => column.id === '9999')

  QUnit.module('when updating column sort settings', () => {
    test('sorts the grid columns when the API call completes', async () => {
      await gradebook.handleViewOptionsUpdated({
        columnSortSettings: {criterion: 'points', direction: 'ascending'},
      })
      deepEqual(gradebook.gridData.columns.scrollable, [
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2201',
        'total_grade',
        'total_grade_override',
      ])
    })
  })

  QUnit.module('when updating view settings', () => {
    QUnit.module('when the notes column does not exist', () => {
      test('calls the createTeacherNotesColumn API function if showNotes is true', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: true})
        strictEqual(GradebookApi.createTeacherNotesColumn.callCount, 1)
        deepEqual(GradebookApi.createTeacherNotesColumn.lastCall.args, ['100'])
      })

      test('does not call createTeacherNotesColumn if showNotes is false', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: false})
        strictEqual(GradebookApi.createTeacherNotesColumn.callCount, 0)
      })

      test('shows the notes column when the API call completes', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: true})
        ok(teacherNotesColumn())
      })

      test('does not update the visibility of the notes column if the API call fails', async () => {
        QUnit.expect(1)
        GradebookApi.createTeacherNotesColumn.rejects(new Error('NO!'))

        try {
          await gradebook.handleViewOptionsUpdated({showNotes: true})
        } catch {
          notOk(teacherNotesColumn())
        }
      })
    })

    QUnit.module('when the notes column already exists', createColumnHooks => {
      createColumnHooks.beforeEach(() => {
        gradebook.gotCustomColumns([
          {id: '9999', teacher_notes: true, hidden: false, title: 'Notes'},
        ])
      })

      test('calls the updateTeacherNotesColumn API function if showNotes changes', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: false})
        strictEqual(GradebookApi.updateTeacherNotesColumn.callCount, 1)
        deepEqual(GradebookApi.updateTeacherNotesColumn.lastCall.args, [
          '100',
          '9999',
          {hidden: true},
        ])
      })

      test('does not call updateTeacherNotesColumn if showNotes has not changed', async () => {
        await gradebook.handleViewOptionsUpdated({showNotes: true})
        strictEqual(GradebookApi.updateTeacherNotesColumn.callCount, 0)
      })

      QUnit.module('when the API call completes', () => {
        test('shows the notes column if showNotes was set to true', async () => {
          gradebook.hideNotesColumn()

          await gradebook.handleViewOptionsUpdated({showNotes: true})
          ok(teacherNotesColumn())
        })

        test('hides the notes column if showNotes was set to false', async () => {
          gradebook.showNotesColumn()

          await gradebook.handleViewOptionsUpdated({showNotes: false})
          notOk(teacherNotesColumn())
        })
      })

      test('does not update the visibility of the notes column if the API call fails', async () => {
        QUnit.expect(1)
        GradebookApi.updateTeacherNotesColumn.rejects(new Error('NOOOOO'))

        try {
          await gradebook.handleViewOptionsUpdated({showNotes: false})
        } catch {
          strictEqual(teacherNotesColumn().hidden, false)
        }
      })
    })

    QUnit.module('when updating items stored in user settings', () => {
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
          })
        )

        strictEqual(GradebookApi.saveUserSettings.callCount, 1)
        const [courseId, params] = GradebookApi.saveUserSettings.lastCall.args
        strictEqual(courseId, '100')
        strictEqual(params.colors.dropped, '#000000')
        strictEqual(params.show_unpublished_assignments, 'true')
        strictEqual(params.view_ungraded_as_zero, 'true')
      })

      test('does not call saveUserSettings if no value has changed', async () => {
        await gradebook.handleViewOptionsUpdated(updateParams())
        strictEqual(GradebookApi.saveUserSettings.callCount, 0)
      })

      QUnit.module('updating showSeparateFirstLastNames assignments', () => {
        test('shows separate last/first names when showSeparateFirstLastNames is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({showSeparateFirstLastNames: true}))
          deepEqual(gradebook.gridData.columns.frozen, ['student_lastname', 'student_firstname'])
        })

        test('shows student name when showSeparateFirstLastNames is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(
            updateParams({showSeparateFirstLastNames: false})
          )
          deepEqual(gradebook.gridData.columns.frozen, ['student'])
        })

        test('does not update student columns if the request fails', async () => {
          QUnit.expect(1)
          GradebookApi.saveUserSettings.rejects(new Error('no way'))

          try {
            await gradebook.handleViewOptionsUpdated(
              updateParams({showSeparateFirstLastNames: true})
            )
          } catch {
            deepEqual(gradebook.gridData.columns.frozen, ['student'])
          }
        })
      })

      QUnit.module('updating hideAssignmentGroupTotals', () => {
        test('hides Assignment Group Total columns when hideAssignmentGroupTotals is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideAssignmentGroupTotals: true}))
          notOk(gradebook.gridData.columns.scrollable.includes('assignment_group_2201'))
        })

        test('shows Assignment Group Total columns when hideAssignmentGroupTotals is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideAssignmentGroupTotals: false}))
          ok(gradebook.gridData.columns.scrollable.includes('assignment_group_2201'))
        })

        test('does not hide Assignment Group Total columns if the request fails', async () => {
          QUnit.expect(1)
          GradebookApi.saveUserSettings.rejects(new Error('no way'))

          try {
            await gradebook.handleViewOptionsUpdated(
              updateParams({hideAssignmentGroupTotals: true})
            )
          } catch {
            ok(gradebook.gridData.columns.scrollable.includes('assignment_group_2201'))
          }
        })
      })

      QUnit.module('updating hideTotal', () => {
        test('hides Total column when hideTotal is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: true}))
          notOk(gradebook.gridData.columns.scrollable.includes('total'))
        })

        test('shows Total columns when hideTotal is set to false', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: false}))
          ok(gradebook.gridData.columns.scrollable.includes('total_grade'))
        })

        test('does not hide Total column if the request fails', async () => {
          QUnit.expect(1)
          GradebookApi.saveUserSettings.rejects(new Error('no way'))

          try {
            await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: true}))
          } catch {
            ok(gradebook.gridData.columns.scrollable.includes('total_grade'))
          }
        })

        test('hides Override columnn when hideTotal is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({hideTotal: true}))
          notOk(gradebook.gridData.columns.scrollable.includes('total_grade_override'))
        })
      })

      QUnit.module('updating showing unpublished assignments', () => {
        test('shows unpublished assignments when showUnpublishedAssignments is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({showUnpublishedAssignments: true}))
          ok(gradebook.gridData.columns.scrollable.includes('assignment_2303'))
        })

        test('hides unpublished assignments when showUnpublishedAssignments is set to false', async () => {
          gradebook.gridDisplaySettings.showUnpublishedAssignments = true
          gradebook.setVisibleGridColumns()

          await gradebook.handleViewOptionsUpdated(
            updateParams({showUnpublishedAssignments: false})
          )
          notOk(gradebook.gridData.columns.scrollable.includes('assignment_2303'))
        })

        test('does not update the list of visible assignments if the request fails', async () => {
          QUnit.expect(1)
          GradebookApi.saveUserSettings.rejects(new Error('no way'))

          try {
            await gradebook.handleViewOptionsUpdated(
              updateParams({showUnpublishedAssignments: true})
            )
          } catch {
            notOk(gradebook.gridData.columns.scrollable.includes('assignment_2303'))
          }
        })
      })

      QUnit.module('updating view ungraded as zero', () => {
        test('makes updates to the grid when the request completes', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({viewUngradedAsZero: true}))
          strictEqual(gradebook.updateAllTotalColumns.callCount, 1)
          strictEqual(gradebook.gridDisplaySettings.viewUngradedAsZero, true)
        })

        test('does not make updates to grid if the request fails', async () => {
          QUnit.expect(2)
          GradebookApi.saveUserSettings.rejects(new Error('STILL NO'))

          try {
            await gradebook.handleViewOptionsUpdated(updateParams({viewUngradedAsZero: true}))
          } catch {
            strictEqual(gradebook.updateAllTotalColumns.callCount, 0)
            strictEqual(gradebook.gridDisplaySettings.viewUngradedAsZero, false)
          }
        })
      })

      QUnit.module('updating status colors', () => {
        test('updates the grid colors when the request completes', async () => {
          // FIXME need to render this dumb gradebook component so setState can happen
          const newColors = {...gradebook.state.gridColors, dropped: '#AAAAAA'}

          await gradebook.handleViewOptionsUpdated(updateParams({statusColors: newColors}))
          strictEqual(gradebook.state.gridColors.dropped, '#AAAAAA')
        })

        test('does not update the grid colors if the request fails', async () => {
          QUnit.expect(1)
          GradebookApi.saveUserSettings.rejects(new Error('no :|'))

          const oldColors = gradebook.state.gridColors

          try {
            await gradebook.handleViewOptionsUpdated(
              updateParams({statusColors: {dropped: '#AAAAAA'}})
            )
          } catch {
            deepEqual(gradebook.state.gridColors, oldColors)
          }
        })
      })
    })

    test('does not update the grid until all requests complete', async () => {
      let resolveSettingsRequest

      GradebookApi.saveUserSettings.returns(
        new Promise(resolve => {
          resolveSettingsRequest = resolve
        })
      )

      const promise = gradebook.handleViewOptionsUpdated({
        columnSortSettings: {criterion: 'points', direction: 'ascending'},
        showNotes: true,
        showUnpublishedAssignments: true,
      })

      strictEqual(gradebook.updateGrid.callCount, 0)

      resolveSettingsRequest()
      await promise

      ok(gradebook.updateGrid.called)
    })

    QUnit.module('when updates have completed', () => {
      QUnit.module('when at least one API call has failed', failureHooks => {
        failureHooks.beforeEach(() => {
          GradebookApi.saveUserSettings.rejects(new Error('...'))
          oldEnv = window.ENV
          window.ENV = {FEATURES: {instui_nav: false}}
        })

        failureHooks.afterEach(() => {
          window.ENV = oldEnv
        })

        test('shows a flash error', async () => {
          QUnit.expect(1)

          try {
            await gradebook.handleViewOptionsUpdated({
              columnSortSettings: {criterion: 'points', direction: 'ascending'},
              showNotes: true,
              showUnpublishedAssignments: true,
            })
          } catch {
            strictEqual(FlashAlert.showFlashError.callCount, 1)
          }
        })

        test('nevertheless updates the grid', async () => {
          QUnit.expect(1)

          try {
            await gradebook.handleViewOptionsUpdated({
              columnSortSettings: {criterion: 'points', direction: 'ascending'},
              showNotes: true,
              showUnpublishedAssignments: true,
            })
          } catch {
            ok(gradebook.updateGrid.called)
          }
        })
      })

      test('updates the grid if all requests succeeded', async () => {
        await gradebook.handleViewOptionsUpdated({
          columnSortSettings: {criterion: 'points', direction: 'ascending'},
          showNotes: true,
          showUnpublishedAssignments: true,
        })
        ok(gradebook.updateGrid.called)
      })
    })
  })
})

QUnit.module('Gradebook#toggleShowSeparateFirstLastNames', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: sinon.stub(),
      },
      settings: {
        allow_separate_first_last_names: 'true',
      },
    })

    sandbox.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
  })

  test('toggles showSeparateFirstLastNames to true when false', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleShowSeparateFirstLastNames()

    strictEqual(gradebook.gridDisplaySettings.showSeparateFirstLastNames, true)
  })

  test('toggles showSeparateFirstLastNames to false when true', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleShowSeparateFirstLastNames()

    strictEqual(gradebook.gridDisplaySettings.showSeparateFirstLastNames, false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = true
    const stubFn = sandbox
      .stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      .callsFake(() => {
        strictEqual(gradebook.gridDisplaySettings.showSeparateFirstLastNames, false)
      })
    gradebook.toggleShowSeparateFirstLastNames()

    strictEqual(stubFn.callCount, 1)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.showSeparateFirstLastNames = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleShowSeparateFirstLastNames()

    deepEqual(gradebook.saveSettings.firstCall.args[0], {
      showSeparateFirstLastNames: true,
    })
  })
})

QUnit.module('Gradebook#toggleHideAssignmentGroupTotals', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: sinon.stub(),
      },
    })

    sandbox.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
  })

  test('toggles hideAssignmentGroupTotals to true when false', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideAssignmentGroupTotals()

    strictEqual(gradebook.gridDisplaySettings.hideAssignmentGroupTotals, true)
  })

  test('toggles hideAssignmentGroupTotals to false when true', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideAssignmentGroupTotals()

    strictEqual(gradebook.gridDisplaySettings.hideAssignmentGroupTotals, false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = true
    const stubFn = sandbox
      .stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      .callsFake(() => {
        strictEqual(gradebook.gridDisplaySettings.hideAssignmentGroupTotals, false)
      })
    gradebook.toggleHideAssignmentGroupTotals()

    strictEqual(stubFn.callCount, 1)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleHideAssignmentGroupTotals()

    deepEqual(gradebook.saveSettings.firstCall.args[0], {
      hideAssignmentGroupTotals: true,
    })
  })
})

QUnit.module('Gradebook#toggleHideTotal', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: sinon.stub(),
      },
    })

    sandbox.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
  })

  test('toggles hideTotal to true when false', () => {
    gradebook.gridDisplaySettings.hideTotal = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideTotal()

    strictEqual(gradebook.gridDisplaySettings.hideTotal, true)
  })

  test('toggles hideTotal to false when true', () => {
    gradebook.gridDisplaySettings.hideTotal = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleHideTotal()

    strictEqual(gradebook.gridDisplaySettings.hideTotal, false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.hideTotal = true
    const stubFn = sandbox
      .stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      .callsFake(() => {
        strictEqual(gradebook.gridDisplaySettings.hideTotal, false)
      })
    gradebook.toggleHideTotal()
    strictEqual(stubFn.callCount, 1)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.hideTotal = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleHideTotal()

    deepEqual(gradebook.saveSettings.firstCall.args[0], {
      hideTotal: true,
    })
  })
})

QUnit.module('Gradebook#updateColumnsAndRenderGradebookSettingsModal', moduleHooks => {
  let gradebook

  moduleHooks.beforeEach(() => {
    setFixtureHtml($fixtures)
    gradebook = createGradebook()
    sinon.stub(gradebook, 'updateColumns')
    sinon.stub(gradebook, 'renderGradebookSettingsModal')
  })

  moduleHooks.afterEach(() => {
    gradebook.destroy()
    $fixtures.innerHTML = ''
  })

  test('calls updateColumns', () => {
    gradebook.updateColumnsAndRenderGradebookSettingsModal()
    strictEqual(gradebook.updateColumns.callCount, 1)
  })

  test('calls renderGradebookSettingsModal', () => {
    gradebook.updateColumnsAndRenderGradebookSettingsModal()
    strictEqual(gradebook.renderGradebookSettingsModal.callCount, 1)
  })
})
