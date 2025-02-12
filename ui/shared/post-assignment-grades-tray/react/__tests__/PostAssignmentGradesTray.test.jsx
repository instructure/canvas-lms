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
import PostAssignmentGradesTray from '..'
import * as Api from '@canvas/post-assignment-grades-tray/react/Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('@canvas/post-assignment-grades-tray/react/Api')

describe('PostAssignmentGradesTray', () => {
  let tray
  let defaultProps
  let mockOnExited
  let mockOnPosted

  const renderTray = (props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    render(<PostAssignmentGradesTray {...mergedProps} ref={ref => (tray = ref)} />)
  }

  beforeEach(() => {
    mockOnExited = jest.fn()
    mockOnPosted = jest.fn()

    defaultProps = {
      assignment: {
        anonymousGrading: false,
        gradesPublished: true,
        id: '2301',
        name: 'Math 1.1',
        postManually: false,
      },
      onExited: mockOnExited,
      onPosted: mockOnPosted,
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
    }

    FlashAlert.showFlashAlert = jest.fn()
    Api.postAssignmentGrades = jest.fn()
    Api.resolvePostAssignmentGradesStatus = jest.fn()
    Api.postAssignmentGradesForSections = jest.fn()
  })

  afterEach(() => {
    FlashAlert.destroyContainer = jest.fn()
    jest.clearAllMocks()
  })

  const waitForTrayToOpen = async () => {
    await waitFor(() => {
      expect(screen.getByRole('dialog', {name: 'Post grades tray'})).toBeInTheDocument()
    })
  }

  describe('show', () => {
    it('opens the tray', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      expect(screen.getByRole('dialog', {name: 'Post grades tray'})).toBeInTheDocument()
    })

    it('displays the name of the assignment', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      expect(screen.getByRole('heading', {name: 'Math 1.1'})).toBeInTheDocument()
    })

    it('resets the "Specific Sections" toggle', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()

      const toggle = screen.getByRole('checkbox', {name: /specific sections/i})
      await userEvent.click(toggle)

      await tray.show(defaultProps)
      await waitForTrayToOpen()

      expect(toggle).not.toBeChecked()
    })

    it('resets the selected sections', async () => {
      Api.postAssignmentGradesForSections.mockResolvedValue({
        id: '23',
        workflowState: 'queued',
      })

      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()

      const toggle = screen.getByRole('checkbox', {name: /specific sections/i})
      await userEvent.click(toggle)
      await userEvent.click(screen.getByLabelText('Sophomores'))

      await tray.show(defaultProps)
      await waitForTrayToOpen()

      await userEvent.click(toggle)
      await userEvent.click(screen.getByLabelText('Freshmen'))
      await userEvent.click(screen.getByRole('button', {name: 'Post'}))

      expect(Api.postAssignmentGradesForSections).toHaveBeenCalledWith('2301', ['2001'], {
        gradedOnly: false,
      })
    })
  })

  describe('Close Button', () => {
    it('closes the tray', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()

      const closeButtons = screen.getAllByRole('button', {name: /close/i})
      await userEvent.click(closeButtons[1]) // Use the second Close button like in QUnit test
      await waitFor(() => {
        expect(mockOnExited).toHaveBeenCalledTimes(1)
      })
    })

    it('calls optional onExited', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()

      const closeButtons = screen.getAllByRole('button', {name: /close/i})
      await userEvent.click(closeButtons[1]) // Use the second Close button like in QUnit test
      await waitFor(() => {
        expect(mockOnExited).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('Specific Sections toggle', () => {
    it('is present', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      expect(screen.getByRole('checkbox', {name: /specific sections/i})).toBeInTheDocument()
    })

    it('does not display the sections when unchecked', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      expect(screen.queryByLabelText('Freshmen')).not.toBeInTheDocument()
    })

    it('shows the sections when checked', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()

      await userEvent.click(screen.getByRole('checkbox', {name: /specific sections/i}))
      expect(screen.getByLabelText('Freshmen')).toBeInTheDocument()
    })

    it('is not shown when there are no sections', async () => {
      renderTray({sections: []})
      await tray.show({...defaultProps, sections: []})
      await waitForTrayToOpen()
      expect(screen.queryByRole('checkbox', {name: /specific sections/i})).not.toBeInTheDocument()
    })
  })

  describe('unposted summary', () => {
    describe('with unposted submissions', () => {
      it('counts graded submissions without a postedAt', async () => {
        const props = {
          ...defaultProps,
          submissions: [
            {postedAt: new Date().toISOString(), score: 1, workflowState: 'graded'},
            {postedAt: null, score: 1, workflowState: 'graded'},
            {postedAt: null, score: null, workflowState: 'unsubmitted'},
          ],
        }
        renderTray(props)
        await tray.show(props)
        await waitForTrayToOpen()
        expect(screen.getByText('1')).toBeInTheDocument()
      })

      it('counts submissions with postable comments and without a postedAt', async () => {
        const props = {
          ...defaultProps,
          submissions: [
            {postedAt: new Date().toISOString(), hasPostableComments: true},
            {postedAt: null, score: 1, workflowState: 'graded'},
            {postedAt: null, score: null, workflowState: 'unsubmitted'},
          ],
        }
        renderTray(props)
        await tray.show(props)
        await waitForTrayToOpen()
        expect(screen.getByText('1')).toBeInTheDocument()
      })
    })

    describe('with no unposted submissions', () => {
      it('does not display a summary of unposted submissions', async () => {
        const props = {
          ...defaultProps,
          submissions: [
            {postedAt: new Date().toISOString(), score: 1, workflowState: 'graded'},
            {postedAt: new Date().toISOString(), score: 1, workflowState: 'graded'},
          ],
        }
        renderTray(props)
        await tray.show(props)
        await waitForTrayToOpen()
        expect(screen.queryByTestId('unposted-summary')).not.toBeInTheDocument()
      })
    })
  })

  describe('Post Button', () => {
    const PROGRESS_ID = 23

    beforeEach(() => {
      Api.postAssignmentGrades.mockResolvedValue({
        id: PROGRESS_ID,
        workflowState: 'queued',
      })
      Api.resolvePostAssignmentGradesStatus.mockResolvedValue()
    })

    it('is present', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      expect(screen.getByRole('button', {name: 'Post'})).toBeInTheDocument()
    })

    it('calls postAssignmentGrades with correct assignment id', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      await userEvent.click(screen.getByRole('button', {name: 'Post'}))
      expect(Api.postAssignmentGrades).toHaveBeenCalledWith('2301', expect.any(Object))
    })

    it('calls resolvePostAssignmentGradesStatus', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      await userEvent.click(screen.getByRole('button', {name: 'Post'}))
      expect(Api.resolvePostAssignmentGradesStatus).toHaveBeenCalledTimes(1)
    })

    it('displays the assignment name while posting grades is in progress', async () => {
      let resolveStatus
      Api.resolvePostAssignmentGradesStatus.mockImplementation(
        () => new Promise(resolve => (resolveStatus = resolve)),
      )

      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      await userEvent.click(screen.getByRole('button', {name: 'Post'}))
      expect(screen.getByRole('heading', {name: 'Math 1.1'})).toBeInTheDocument()
      resolveStatus()
    })

    it('calls onPosted', async () => {
      renderTray()
      await tray.show(defaultProps)
      await waitForTrayToOpen()
      await userEvent.click(screen.getByRole('button', {name: 'Post'}))
      expect(mockOnPosted).toHaveBeenCalledTimes(1)
    })

    describe('pending request', () => {
      it('displays a spinner', async () => {
        let resolveStatus
        Api.resolvePostAssignmentGradesStatus.mockImplementation(
          () => new Promise(resolve => (resolveStatus = resolve)),
        )

        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(screen.getByRole('img', {name: 'Posting grades'})).toBeInTheDocument()
        resolveStatus()
      })
    })

    describe('on success', () => {
      it('renders a success alert with correct message', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'Success! Grades have been posted to everyone for Math 1.1.',
          type: 'success',
        })
      })

      it('does not render an alert if launched from SpeedGrader and assignment is anonymous', async () => {
        const props = {
          ...defaultProps,
          containerName: 'SPEED_GRADER',
          assignment: {...defaultProps.assignment, anonymousGrading: true},
        }
        renderTray(props)
        await tray.show(props)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(FlashAlert.showFlashAlert).not.toHaveBeenCalled()
      })
    })

    describe('gradedOnly', () => {
      it('passes gradedOnly true when Graded is selected', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('radio', {name: /graded/i}))
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(Api.postAssignmentGrades).toHaveBeenCalledWith('2301', {gradedOnly: true})
      })

      it('passes gradedOnly false when Everyone is selected', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('radio', {name: /everyone/i}))
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(Api.postAssignmentGrades).toHaveBeenCalledWith('2301', {gradedOnly: false})
      })

      it('shows success message indicating posting was only for graded', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('radio', {name: /graded/i}))
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'Success! Grades have been posted to everyone graded for Math 1.1.',
          type: 'success',
        })
      })
    })

    describe('on failure', () => {
      beforeEach(() => {
        Api.postAssignmentGrades.mockRejectedValue(new Error('ERROR'))
      })

      it('renders an error alert with correct message', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
          message: 'There was a problem posting assignment grades.',
          type: 'error',
        })
      })

      it('keeps tray open', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(screen.getByRole('dialog')).toBeInTheDocument()
      })

      it('removes spinner', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        await userEvent.click(screen.getByRole('button', {name: 'Post'}))
        expect(screen.queryByRole('img', {name: 'Posting grades'})).not.toBeInTheDocument()
      })
    })

    describe('posting for sections', () => {
      beforeEach(() => {
        Api.postAssignmentGradesForSections.mockResolvedValue({
          id: PROGRESS_ID,
          workflowState: 'queued',
        })
      })

      it('enables section toggle when assignment is not anonymous', async () => {
        renderTray()
        await tray.show(defaultProps)
        await waitForTrayToOpen()
        expect(screen.getByRole('checkbox', {name: /specific sections/i})).not.toBeDisabled()
      })

      it('disables section toggle when assignment is anonymous', async () => {
        const props = {
          ...defaultProps,
          assignment: {...defaultProps.assignment, anonymousGrading: true},
        }
        renderTray(props)
        await tray.show(props)
        await waitForTrayToOpen()
        expect(screen.getByRole('checkbox', {name: /specific sections/i})).toBeDisabled()
      })

      describe('with section toggle clicked', () => {
        it('shows error when no sections are selected', async () => {
          renderTray()
          await tray.show(defaultProps)
          await waitForTrayToOpen()
          await userEvent.click(screen.getByRole('checkbox', {name: /specific sections/i}))
          await userEvent.click(screen.getByRole('button', {name: 'Post'}))
          expect(screen.getByText('Please select at least one option')).toBeInTheDocument()
        })

        it('shows success message when sections are selected and posting succeeds', async () => {
          renderTray()
          await tray.show(defaultProps)
          await waitForTrayToOpen()
          await userEvent.click(screen.getByRole('checkbox', {name: /specific sections/i}))
          await userEvent.click(screen.getByLabelText('Sophomores'))
          await userEvent.click(screen.getByRole('button', {name: 'Post'}))
          expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
            message: 'Success! Grades have been posted for the selected sections of Math 1.1.',
            type: 'success',
          })
        })
      })
    })
  })
})
