/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {createGradebook, defaultGradebookProps} from '../../__tests__/GradebookSpecHelper'
import {render, within} from '@testing-library/react'
import Gradebook from '../../Gradebook'
import GradebookApi from '../../apis/GradebookApi'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

import '@testing-library/jest-dom/extend-expect'

jest.mock('../../apis/GradebookApi')
jest.mock('@canvas/alerts/react/FlashAlert')

describe('Gradebook', () => {
  it('GradebookMenu is rendered', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gradebookMenuNode={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook/i))
  })

  describe('#handleViewOptionsUpdated', () => {
    let gradebook

    beforeEach(() => {
      gradebook = createGradebook({
        allow_view_ungraded_as_zero: true,
        context_id: '100',
        enhanced_gradebook_filters: true,
        settings: {
          show_unpublished_assignments: false
        },
        view_ungraded_as_zero: false
      })

      gradebook.gotAllAssignmentGroups([
        {
          id: '2201',
          position: 1,
          name: 'Assignments',
          assignments: [
            {id: '2301', name: 'assignment1', points_possible: 100, published: true},
            {id: '2302', name: 'assignment2', points_possible: 50, published: true},
            {id: '2303', name: 'unpublished', points_possible: 1500, published: false}
          ]
        }
      ])

      gradebook.createGrid = jest.fn()
      gradebook.renderGridColor = jest.fn()
      gradebook.updateGrid = jest.fn()
      gradebook.updateAllTotalColumns = jest.fn()

      gradebook.setColumnOrder({sortType: 'due_date', direction: 'ascending'})
      gradebook.gotCustomColumns([])
      gradebook.initGrid()

      GradebookApi.createTeacherNotesColumn = jest.fn().mockResolvedValue({
        data: {
          id: '9999',
          hidden: false,
          name: 'Notes',
          position: 1,
          teacher_notes: true
        }
      })
      GradebookApi.saveUserSettings = jest.fn(() => Promise.resolve())
      GradebookApi.updateColumnOrder = jest.fn(() => Promise.resolve())
      GradebookApi.updateTeacherNotesColumn = jest.fn(() => Promise.resolve())

      FlashAlert.showFlashError = jest.fn(() => {})
    })

    describe('when updating column sort settings', () => {
      it('calls the updateColumnOrder API function with the updated settings', async () => {
        await gradebook.handleViewOptionsUpdated({
          columnSortSettings: {criterion: 'points', direction: 'ascending'}
        })

        expect(GradebookApi.updateColumnOrder).toHaveBeenCalledWith('100', {
          direction: 'ascending',
          sortType: 'points',
          freezeTotalGrade: false
        })
      })

      it('does not call updateColumnOrder if the column settings have not changed', async () => {
        gradebook.setColumnOrder({sortType: 'due_date', direction: 'ascending'})
        await gradebook.handleViewOptionsUpdated({
          columnSortSettings: {criterion: 'due_date', direction: 'ascending'}
        })
        expect(GradebookApi.updateColumnOrder).not.toHaveBeenCalled()
      })

      it('sorts the grid columns when the API call completes', async () => {
        await gradebook.handleViewOptionsUpdated({
          columnSortSettings: {criterion: 'points', direction: 'ascending'}
        })
        expect(gradebook.gridData.columns.scrollable).toEqual([
          'assignment_2302',
          'assignment_2301',
          'assignment_group_2201',
          'total_grade'
        ])
      })

      it('does not sort the grid columns if the API call fails', async () => {
        expect.hasAssertions()
        GradebookApi.updateColumnOrder.mockRejectedValue(new Error('no'))

        try {
          await gradebook.handleViewOptionsUpdated({
            columnSortSettings: {criterion: 'points', direction: 'ascending'}
          })
        } catch {
          expect(gradebook.gridData.columns.scrollable).toEqual([
            'assignment_2301',
            'assignment_2302',
            'assignment_group_2201',
            'total_grade'
          ])
        }
      })
    })

    describe('when updating teacher notes settings', () => {
      const createExistingNotesColumn = () =>
        gradebook.gotCustomColumns([
          {id: '9999', teacher_notes: true, hidden: false, title: 'Notes'}
        ])

      describe('when the notes column does not exist', () => {
        it('calls the createTeacherNotesColumn API function if showNotes is true', async () => {
          await gradebook.handleViewOptionsUpdated({showNotes: true})
          expect(GradebookApi.createTeacherNotesColumn).toHaveBeenCalledWith('100')
        })

        it('adds the Notes column to gradebook', async () => {
          await gradebook.handleViewOptionsUpdated({showNotes: true})
          expect(gradebook.listVisibleCustomColumns()).toContainEqual(
            expect.objectContaining({id: '9999'})
          )
        })

        it('does not call createTeacherNotesColumn if showNotes is false', async () => {
          await gradebook.handleViewOptionsUpdated({showNotes: false})
          expect(GradebookApi.createTeacherNotesColumn).not.toHaveBeenCalled()
        })

        describe('when the API call completes', () => {
          it('shows the notes column', async () => {
            await gradebook.handleViewOptionsUpdated({showNotes: true})
            expect(gradebook.listVisibleCustomColumns()).toContainEqual(
              expect.objectContaining({id: '9999'})
            )
          })
        })

        it('does not update the visibility of the notes column if the API call fails', async () => {
          expect.hasAssertions()
          GradebookApi.createTeacherNotesColumn.mockRejectedValue(new Error('.'))

          try {
            await gradebook.handleViewOptionsUpdated({showNotes: true})
          } catch {
            expect(gradebook.listVisibleCustomColumns()).not.toContainEqual(
              expect.objectContaining({id: '9999'})
            )
          }
        })
      })

      describe('when the notes column already exists', () => {
        beforeEach(() => {
          createExistingNotesColumn()
        })

        it('calls the updateTeacherNotesColumn API function if showNotes changes', async () => {
          await gradebook.handleViewOptionsUpdated({showNotes: false})
          expect(GradebookApi.updateTeacherNotesColumn).toHaveBeenCalledWith('100', '9999', {
            hidden: true
          })
        })

        it('does not call updateTeacherNotesColumn if showNotes has not changed', async () => {
          await gradebook.handleViewOptionsUpdated({showNotes: true})
          expect(GradebookApi.updateTeacherNotesColumn).not.toHaveBeenCalled()
        })

        describe('when the API call completes', () => {
          it('shows the notes column if showNotes was set to true', async () => {
            gradebook.hideNotesColumn()

            await gradebook.handleViewOptionsUpdated({showNotes: true})
            expect(gradebook.listVisibleCustomColumns()).toContainEqual(
              expect.objectContaining({id: '9999'})
            )
          })

          it('hides the notes column if showNotes was set to false', async () => {
            gradebook.showNotesColumn()

            await gradebook.handleViewOptionsUpdated({showNotes: false})
            expect(gradebook.listVisibleCustomColumns()).not.toContainEqual(
              expect.objectContaining({id: '9999'})
            )
          })
        })

        it('does not update the visibility of the notes column if the API call fails', async () => {
          expect.hasAssertions()
          GradebookApi.updateTeacherNotesColumn.mockRejectedValue(new Error('.'))

          try {
            await gradebook.handleViewOptionsUpdated({showNotes: false})
          } catch {
            expect(gradebook.listVisibleCustomColumns()).not.toContain(
              expect.objectContaining({id: '9999'})
            )
          }
        })
      })
    })

    describe('when updating items stored in user settings', () => {
      const updateParams = (overrides = {}) => ({
        showUnpublishedAssignments: false,
        statusColors: gradebook.getGridColors(),
        viewUngradedAsZero: false,
        ...overrides
      })

      it('calls the saveUserSettings API function with the changed values', async () => {
        await gradebook.handleViewOptionsUpdated(
          updateParams({
            showUnpublishedAssignments: true,
            statusColors: {...gradebook.getGridColors(), dropped: '#000000'},
            viewUngradedAsZero: true
          })
        )

        expect(GradebookApi.saveUserSettings).toHaveBeenCalledWith(
          '100',
          expect.objectContaining({
            colors: expect.objectContaining({dropped: '#000000'}),
            show_unpublished_assignments: true,
            view_ungraded_as_zero: true
          })
        )
      })

      it('does not call saveUserSettings if no value has changed', async () => {
        await gradebook.handleViewOptionsUpdated(updateParams())
        expect(GradebookApi.saveUserSettings).not.toHaveBeenCalled()
      })

      describe('updating showing unpublished assignments', () => {
        it('shows unpublished assignments when showUnpublishedAssignments is set to true', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({showUnpublishedAssignments: true}))
          expect(gradebook.gridData.columns.scrollable).toContain('assignment_2303')
        })

        it('hides unpublished assignments when showUnpublishedAssignments is set to false', async () => {
          gradebook.gridDisplaySettings.showUnpublishedAssignments = true
          gradebook.setVisibleGridColumns()

          await gradebook.handleViewOptionsUpdated(
            updateParams({showUnpublishedAssignments: false})
          )
          expect(gradebook.gridData.columns.scrollable).not.toContain('assignment_2303')
        })

        it('does not update the list of visible assignments if the request fails', async () => {
          expect.hasAssertions()
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('!'))

          try {
            await gradebook.handleViewOptionsUpdated(
              updateParams({showUnpublishedAssignments: true})
            )
          } catch {
            expect(gradebook.gridData.columns.scrollable).not.toContain('assignment_2303')
          }
        })
      })

      describe('updating view ungraded as zero', () => {
        it('makes updates to the grid when the request completes', async () => {
          await gradebook.handleViewOptionsUpdated(updateParams({viewUngradedAsZero: true}))
          expect(gradebook.updateAllTotalColumns).toHaveBeenCalled()
          expect(gradebook.gridDisplaySettings.viewUngradedAsZero).toBe(true)
        })

        it('does not make updates to grid if the request fails', async () => {
          expect.hasAssertions()
          GradebookApi.saveUserSettings.mockRejectedValue(new Error(':|'))

          try {
            await gradebook.handleViewOptionsUpdated(updateParams({viewUngradedAsZero: true}))
          } catch {
            expect(gradebook.updateAllTotalColumns).not.toHaveBeenCalled()
            expect(gradebook.gridDisplaySettings.viewUngradedAsZero).toBe(false)
          }
        })
      })

      describe('updating status colors', () => {
        it('updates the grid colors when the request completes', async () => {
          const newColors = {...gradebook.getGridColors(), dropped: '#AAAAAA'}

          await gradebook.handleViewOptionsUpdated(updateParams({statusColors: newColors}))
          expect(gradebook.getGridColors().dropped).toBe('#AAAAAA')
        })

        it('does not update the grid colors if the request fails', async () => {
          expect.hasAssertions()
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('?'))

          const oldColors = gradebook.getGridColors()

          try {
            await gradebook.handleViewOptionsUpdated(
              updateParams({statusColors: {dropped: '#AAAAAA'}})
            )
          } catch {
            expect(gradebook.getGridColors()).toEqual(oldColors)
          }
        })
      })
    })

    it('does not update the grid until all requests complete', async () => {
      let resolveSettingsRequest

      GradebookApi.saveUserSettings.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveSettingsRequest = resolve
          })
      )

      const promise = gradebook.handleViewOptionsUpdated({
        columnSortSettings: {criterion: 'points', direction: 'ascending'},
        showNotes: true,
        showUnpublishedAssignments: true
      })

      expect(gradebook.updateGrid).not.toHaveBeenCalled()

      resolveSettingsRequest()
      await promise

      expect(gradebook.updateGrid).toHaveBeenCalled()
    })

    describe('when updates have completed', () => {
      describe('when at least one API call has failed', () => {
        beforeEach(() => {
          GradebookApi.saveUserSettings.mockRejectedValue(new Error('...'))
        })

        it('shows a flash error', async () => {
          expect.hasAssertions()

          try {
            await gradebook.handleViewOptionsUpdated({
              columnSortSettings: {criterion: 'points', direction: 'ascending'},
              showNotes: true,
              showUnpublishedAssignments: true
            })
          } catch {
            expect(FlashAlert.showFlashError).toHaveBeenCalled()
          }
        })

        it('nevertheless updates the grid', async () => {
          expect.hasAssertions()

          try {
            await gradebook.handleViewOptionsUpdated({
              columnSortSettings: {criterion: 'points', direction: 'ascending'},
              showNotes: true,
              showUnpublishedAssignments: true
            })
          } catch {
            expect(gradebook.updateGrid).toHaveBeenCalled()
          }
        })
      })

      it('updates the grid if all requests succeeded', async () => {
        await gradebook.handleViewOptionsUpdated({
          columnSortSettings: {criterion: 'points', direction: 'ascending'},
          showNotes: true,
          showUnpublishedAssignments: true
        })
        expect(gradebook.updateGrid).toHaveBeenCalled()
      })
    })
  })
})

describe('compareAssignmentPositions', () => {
  it('renders gradebookSettingsModalButton', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} settingsModalButtonContainer={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook Settings/i))
  })
})
