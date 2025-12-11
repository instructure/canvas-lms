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

/* global vi */
if (typeof vi !== 'undefined') {
  vi.mock('@canvas/hide-assignment-grades-tray/react/Api')
  vi.mock('@canvas/alerts/react/FlashAlert')
}
jest.mock('@canvas/hide-assignment-grades-tray/react/Api')
jest.mock('@canvas/alerts/react/FlashAlert')

import {render, screen as rtlScreen, waitFor, fireEvent} from '@testing-library/react'
import React from 'react'

import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import * as Api from '@canvas/hide-assignment-grades-tray/react/Api'
import HideAssignmentGradesTray from '..'

// Create mock promises that we can control for testing
const createControlledPromise = () => {
  const handlers = {}
  const promise = new Promise((resolve, reject) => {
    handlers.resolve = resolve
    handlers.reject = reject
  })
  return {...handlers, promise}
}

describe('HideAssignmentGradesTray', () => {
  const defaultContext = {
    assignment: {
      anonymousGrading: false,
      gradesPublished: true,
      id: '2301',
      name: 'Math 1.1',
    },
    onExited: jest.fn(),
    onHidden: jest.fn(),
    sections: [
      {id: '2001', name: 'Freshmen'},
      {id: '2002', name: 'Sophomores'},
    ],
    submissions: [],
  }

  let trayRef

  beforeEach(() => {
    trayRef = null
    jest.clearAllMocks()
    // Clean up any previous renders to avoid duplicate elements
    document.body.innerHTML = ''
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderTray = () => {
    return render(
      <HideAssignmentGradesTray
        ref={ref => {
          trayRef = ref
        }}
      />,
    )
  }

  const showTray = async (context = defaultContext) => {
    renderTray()
    trayRef.show(context)

    // Wait for the tray to be fully rendered
    await waitFor(() => {
      expect(rtlScreen.getByText('Math 1.1')).toBeInTheDocument()
    })
  }

  it('displays the assignment name when opened', async () => {
    await showTray()
    expect(rtlScreen.getByText('Math 1.1')).toBeInTheDocument()
  })

  describe('sections functionality', () => {
    it('does not display sections by default', async () => {
      await showTray()

      // The checkbox for specific sections should be present but not checked
      const specificSectionsCheckbox = rtlScreen.getByText('Specific Sections')
      expect(specificSectionsCheckbox).toBeInTheDocument()

      // Section checkboxes should not be visible initially
      expect(rtlScreen.queryByText('Freshmen')).not.toBeInTheDocument()
    })

    it('shows sections when "Specific Sections" is selected', async () => {
      await showTray()

      // Click the specific sections checkbox
      const checkbox = rtlScreen.getByRole('checkbox', {name: 'Specific Sections'})
      fireEvent.click(checkbox)

      // Section checkboxes should now be visible
      expect(rtlScreen.getByText('Freshmen')).toBeInTheDocument()
      expect(rtlScreen.getByText('Sophomores')).toBeInTheDocument()
    })

    it('does not show sections toggle when no sections are available', async () => {
      await showTray({...defaultContext, sections: []})
      expect(rtlScreen.queryByText('Specific Sections')).not.toBeInTheDocument()
    })

    it('resets section selection when reopening the tray', async () => {
      // First open the tray and select sections
      await showTray()
      const checkbox = rtlScreen.getByRole('checkbox', {name: 'Specific Sections'})
      fireEvent.click(checkbox)

      // Close and reopen the tray
      trayRef.dismiss()
      await waitFor(() => {
        expect(defaultContext.onExited).toHaveBeenCalled()
      })

      // Show the tray again with a fresh context
      jest.clearAllMocks()
      document.body.innerHTML = ''
      await showTray()

      // Specific sections should not be checked
      const specificSectionsCheckbox = rtlScreen.getByText('Specific Sections')
      expect(specificSectionsCheckbox).toBeInTheDocument()
      expect(rtlScreen.queryByText('Freshmen')).not.toBeInTheDocument()
    })
  })

  describe('hide functionality', () => {
    it('hides grades for all sections when no specific sections are selected', async () => {
      await showTray()
      const hideButton = rtlScreen.getByRole('button', {name: 'Hide'})
      fireEvent.click(hideButton)
      expect(Api.hideAssignmentGrades).toHaveBeenCalledWith('2301')
    })

    it('hides grades for specific sections when selected', async () => {
      await showTray()

      // Select specific sections
      const specificSectionsCheckbox = rtlScreen.getByRole('checkbox', {name: 'Specific Sections'})
      fireEvent.click(specificSectionsCheckbox)

      // Select a section
      const freshmenCheckbox = rtlScreen.getByRole('checkbox', {name: 'Freshmen'})
      fireEvent.click(freshmenCheckbox)

      // Click hide
      const hideButton = rtlScreen.getByRole('button', {name: 'Hide'})
      fireEvent.click(hideButton)

      expect(Api.hideAssignmentGradesForSections).toHaveBeenCalledWith('2301', ['2001'])
    })

    it('shows an error when no sections are selected with "Specific Sections" checked', async () => {
      await showTray()

      // Select specific sections but don't select any section
      const specificSectionsCheckbox = rtlScreen.getByRole('checkbox', {name: 'Specific Sections'})
      fireEvent.click(specificSectionsCheckbox)

      // Click hide
      const hideButton = rtlScreen.getByRole('button', {name: 'Hide'})
      fireEvent.click(hideButton)

      expect(rtlScreen.getByText('Please select at least one option')).toBeInTheDocument()
    })

    it('shows success message when hiding grades succeeds', async () => {
      // Set up controlled promises for this test
      const hideGradesPromise = createControlledPromise()
      const resolveStatusPromise = createControlledPromise()

      // Override the default mock implementations for this test only
      Api.hideAssignmentGrades.mockReturnValueOnce(hideGradesPromise.promise)
      Api.resolveHideAssignmentGradesStatus.mockReturnValueOnce(resolveStatusPromise.promise)

      await showTray()

      // Click the hide button
      const hideButton = rtlScreen.getByRole('button', {name: 'Hide'})
      fireEvent.click(hideButton)

      // Resolve the first promise
      hideGradesPromise.resolve({id: '1', workflowState: 'completed'})

      // Wait for the first promise to be handled
      await waitFor(() => {
        expect(Api.resolveHideAssignmentGradesStatus).toHaveBeenCalled()
      })

      // Resolve the second promise
      resolveStatusPromise.resolve({})

      // Now wait for the success message
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'Success! Grades have been hidden for Math 1.1.',
          type: 'success',
        })
      })
    })

    it('shows error message when hiding grades fails', async () => {
      const error = new Error('Failed to hide grades')
      Api.hideAssignmentGrades.mockRejectedValueOnce(error)
      await showTray()

      const hideButton = rtlScreen.getByRole('button', {name: 'Hide'})
      fireEvent.click(hideButton)

      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'There was a problem hiding assignment grades.',
          type: 'error',
        })
      })
    })

    // fickle; this test passes individually
    it.skip('disables hide button while processing', async () => {
      const hideAssignmentGradesMock = jest.fn(
        () => new Promise(resolve => setTimeout(resolve, 100)),
      )
      Api.hideAssignmentGrades.mockImplementation(hideAssignmentGradesMock)
      await showTray()

      const hideButton = rtlScreen.getByRole('button', {name: 'Hide'})
      fireEvent.click(hideButton)

      expect(rtlScreen.getByText(/hiding grades/i, {selector: 'span'})).toBeInTheDocument()
      await waitFor(() => {
        expect(rtlScreen.queryByText(/hiding grades/i, {selector: 'span'})).not.toBeInTheDocument()
      })
    })
  })

  describe('close functionality', () => {
    it('closes when clicking the close icon button', async () => {
      await showTray()

      // Find the close button by its role
      const closeButtons = rtlScreen.getAllByRole('button', {name: 'Close'})
      fireEvent.click(closeButtons[0]) // First close button is the icon

      await waitFor(() => {
        expect(defaultContext.onExited).toHaveBeenCalled()
      })
    })

    it('closes when clicking the close button', async () => {
      await showTray()

      // Find the text close button
      const closeButtons = rtlScreen.getAllByRole('button', {name: 'Close'})
      fireEvent.click(closeButtons[1]) // Second close button is the text button

      await waitFor(() => {
        expect(defaultContext.onExited).toHaveBeenCalled()
      })
    })
  })
})
