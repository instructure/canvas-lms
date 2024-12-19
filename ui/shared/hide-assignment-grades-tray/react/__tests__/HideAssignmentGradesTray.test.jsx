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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import HideAssignmentGradesTray from '..'
import * as Api from '@canvas/hide-assignment-grades-tray/react/Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/hide-assignment-grades-tray/react/Api', () => ({
  hideAssignmentGrades: jest.fn().mockResolvedValue(),
  hideAssignmentGradesForSections: jest.fn().mockResolvedValue(),
  resolveHideAssignmentGradesStatus: jest.fn().mockResolvedValue(),
}))

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(),
  showFlashError: jest.fn(),
  showFlashAlert: jest.fn(),
}))

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
      />
    )
  }

  const showTray = async (context = defaultContext) => {
    renderTray()
    trayRef.show(context)
    await waitFor(() => {
      expect(screen.getByRole('heading', {name: 'Math 1.1'})).toBeInTheDocument()
    })
  }

  it('displays the assignment name when opened', async () => {
    await showTray()
    expect(screen.getByRole('heading', {name: 'Math 1.1'})).toBeInTheDocument()
  })

  describe('sections functionality', () => {
    it('does not display sections by default', async () => {
      await showTray()
      expect(screen.queryByRole('checkbox', {name: 'Freshmen'})).not.toBeInTheDocument()
    })

    it('shows sections when "Specific Sections" is selected', async () => {
      await showTray()
      await userEvent.click(screen.getByRole('checkbox', {name: 'Specific Sections'}))
      expect(screen.getByRole('checkbox', {name: 'Freshmen'})).toBeInTheDocument()
      expect(screen.getByRole('checkbox', {name: 'Sophomores'})).toBeInTheDocument()
    })

    it('does not show sections toggle when no sections are available', async () => {
      await showTray({...defaultContext, sections: []})
      expect(screen.queryByRole('checkbox', {name: 'Specific Sections'})).not.toBeInTheDocument()
    })

    it('resets section selection when reopening the tray', async () => {
      await showTray()
      await userEvent.click(screen.getByRole('checkbox', {name: 'Specific Sections'}))
      await userEvent.click(screen.getByRole('checkbox', {name: 'Sophomores'}))

      await showTray()
      expect(screen.queryByRole('checkbox', {name: 'Specific Sections'})).not.toBeChecked()
    })
  })

  describe('hide functionality', () => {
    it('hides grades for all sections when no specific sections are selected', async () => {
      await showTray()
      await userEvent.click(screen.getByRole('button', {name: 'Hide'}))
      expect(Api.hideAssignmentGrades).toHaveBeenCalledWith('2301')
    })

    it('hides grades for specific sections when selected', async () => {
      await showTray()
      await userEvent.click(screen.getByRole('checkbox', {name: 'Specific Sections'}))
      await userEvent.click(screen.getByRole('checkbox', {name: 'Freshmen'}))
      await userEvent.click(screen.getByRole('button', {name: 'Hide'}))
      expect(Api.hideAssignmentGradesForSections).toHaveBeenCalledWith('2301', ['2001'])
    })

    it('shows success message when hiding grades succeeds', async () => {
      await showTray()
      await userEvent.click(screen.getByRole('button', {name: 'Hide'}))
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'Success! Grades have been hidden for Math 1.1.',
          type: 'success',
        })
      })
    })

    it('shows error message when hiding grades fails', async () => {
      const error = new Error('Failed to hide grades')
      Api.hideAssignmentGrades.mockRejectedValue(error)
      await showTray()
      await userEvent.click(screen.getByRole('button', {name: 'Hide'}))
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'There was a problem hiding assignment grades.',
          type: 'error',
        })
      })
    })

    it('disables hide button while processing', async () => {
      const hideAssignmentGradesMock = jest.fn(
        () => new Promise(resolve => setTimeout(resolve, 100))
      )
      Api.hideAssignmentGrades.mockImplementation(hideAssignmentGradesMock)
      await showTray()
      const hideButton = screen.getByRole('button', {name: 'Hide'})
      await userEvent.click(hideButton)
      expect(screen.getByRole('img', {name: 'Hiding grades'})).toBeInTheDocument()
      await waitFor(() => {
        expect(screen.queryByRole('img', {name: 'Hiding grades'})).not.toBeInTheDocument()
      })
    })
  })

  describe('close functionality', () => {
    it('closes when clicking the close icon button', async () => {
      await showTray()
      const closeButtons = screen.getAllByRole('button', {name: 'Close'})
      await userEvent.click(closeButtons[0]) // First close button is the icon
      await waitFor(() => {
        expect(defaultContext.onExited).toHaveBeenCalled()
      })
    })

    it('closes when clicking the close button', async () => {
      await showTray()
      const closeButtons = screen.getAllByRole('button', {name: 'Close'})
      await userEvent.click(closeButtons[1]) // Second close button is the text button
      await waitFor(() => {
        expect(defaultContext.onExited).toHaveBeenCalled()
      })
    })
  })
})
