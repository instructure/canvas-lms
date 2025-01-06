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
// eslint-disable-next-line no-redeclare
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import AssignmentPostingPolicyTray from '../index'
import * as Api from '../Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('../Api')

describe('AssignmentPostingPolicyTray', () => {
  let context
  let tray

  const renderTray = () => {
    const component = render(<AssignmentPostingPolicyTray ref={ref => (tray = ref)} />)
    return component
  }

  const getTray = () => screen.queryByRole('dialog', {name: 'Grade posting policy tray'})

  const getButton = name => screen.getByRole('button', {name})
  const getInput = name => {
    const regex = new RegExp(
      name === 'Automatically'
        ? 'Automatically.*visible to students'
        : 'Manually.*hidden by default',
    )
    return screen.getByRole('radio', {name: regex})
  }

  beforeEach(() => {
    context = {
      assignment: {
        id: '2301',
        name: 'Math 1.1',
        postManually: false,
      },
      onAssignmentPostPolicyUpdated: jest.fn(),
      onExited: jest.fn(),
      onDismiss: jest.fn(),
    }

    FlashAlert.showFlashAlert.mockReset()
    Api.setAssignmentPostPolicy.mockReset()
  })

  afterEach(async () => {
    if (getTray()) {
      await userEvent.click(getButton('Close'))
      await waitFor(() => expect(context.onExited).toHaveBeenCalled())
    }
    jest.clearAllMocks()
  })

  describe('#show()', () => {
    it('opens the tray', async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('includes the name of the assignment', async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => {
        expect(screen.getByText('Grade Posting Policy: Math 1.1')).toBeInTheDocument()
      })
    })

    it('disables the "Automatically" input for an anonymous assignment', async () => {
      context.assignment.anonymousGrading = true
      renderTray()
      tray.show(context)
      await waitFor(() => {
        expect(getInput('Automatically')).toBeDisabled()
      })
    })

    describe('when the assignment is moderated', () => {
      beforeEach(() => {
        context.assignment.moderatedGrading = true
      })

      it('disables the "Automatically" input when grades are not published', async () => {
        context.assignment.gradesPublished = false
        renderTray()
        tray.show(context)
        await waitFor(() => {
          expect(getInput('Automatically')).toBeDisabled()
        })
      })

      it('enables the "Automatically" input when grades are published', async () => {
        context.assignment.gradesPublished = true
        renderTray()
        tray.show(context)
        await waitFor(() => {
          expect(getInput('Automatically')).toBeEnabled()
        })
      })

      it('always disables the "Automatically" input when the assignment is anonymous', async () => {
        context.assignment.anonymousGrading = true
        context.assignment.gradesPublished = true
        renderTray()
        tray.show(context)
        await waitFor(() => {
          expect(getInput('Automatically')).toBeDisabled()
        })
      })
    })

    it('enables the "Automatically" input if the assignment is not anonymous or moderated', async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => {
        expect(getInput('Automatically')).toBeEnabled()
      })
    })

    it('the "Automatically" input is initially selected if an auto-posted assignment is passed', async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => {
        expect(getInput('Automatically')).toBeChecked()
      })
    })

    it('the "Manually" input is initially selected if a manual-posted assignment is passed', async () => {
      context.assignment.postManually = true
      renderTray()
      tray.show(context)
      await waitFor(() => {
        expect(getInput('Manually')).toBeChecked()
      })
    })

    it('enables the "Save" button if the postManually value has changed and no request is in progress', async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
      expect(getButton('Save')).toBeEnabled()
    })

    it('disables the "Save" button if the postManually value has not changed', async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
      await userEvent.click(getInput('Automatically'))
      expect(getButton('Save')).toBeDisabled()
    })

    it('disables the "Save" button if a request is already in progress', async () => {
      let resolveRequest
      Api.setAssignmentPostPolicy.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveRequest = () => {
              resolve({assignmentId: '2301', postManually: true})
            }
          }),
      )

      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
      await userEvent.click(getButton('Save'))
      expect(getButton('Save')).toBeDisabled()
      resolveRequest()
    })
  })

  describe('"Close" Button', () => {
    beforeEach(async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('closes the tray', async () => {
      await userEvent.click(getButton('Close'))
      await waitFor(() => {
        expect(getTray()).not.toBeInTheDocument()
      })
    })
  })

  describe('"Cancel" button', () => {
    beforeEach(async () => {
      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('closes the tray', async () => {
      await userEvent.click(getButton('Cancel'))
      await waitFor(() => {
        expect(getTray()).not.toBeInTheDocument()
      })
    })

    it('is enabled when no request is in progress', () => {
      expect(getButton('Cancel')).toBeEnabled()
    })

    it('is disabled when a request is in progress', async () => {
      let resolveRequest
      Api.setAssignmentPostPolicy.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveRequest = () => {
              resolve({assignmentId: '2301', postManually: true})
            }
          }),
      )

      await userEvent.click(getInput('Manually'))
      await userEvent.click(getButton('Save'))
      expect(getButton('Cancel')).toBeDisabled()
      resolveRequest()
    })
  })

  describe('"Save" button', () => {
    beforeEach(async () => {
      Api.setAssignmentPostPolicy.mockResolvedValue({
        assignmentId: '2301',
        postManually: true,
      })

      renderTray()
      tray.show(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
    })

    afterEach(() => {
      FlashAlert.destroyContainer()
    })

    it('calls setAssignmentPostPolicy', async () => {
      await userEvent.click(getButton('Save'))
      expect(Api.setAssignmentPostPolicy).toHaveBeenCalled()
    })

    it('passes the assignment ID to setAssignmentPostPolicy', async () => {
      await userEvent.click(getButton('Save'))
      expect(Api.setAssignmentPostPolicy).toHaveBeenCalledWith(
        expect.objectContaining({
          assignmentId: '2301',
        }),
      )
    })

    it('passes the selected postManually value to setAssignmentPostPolicy', async () => {
      await userEvent.click(getButton('Save'))
      expect(Api.setAssignmentPostPolicy).toHaveBeenCalledWith(
        expect.objectContaining({
          postManually: true,
        }),
      )
    })

    describe('on success', () => {
      it('renders a success alert', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
        })
      })

      it('the rendered alert includes a message referencing the assignment', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              message: 'Success! The post policy for Math 1.1 has been updated.',
            }),
          )
        })
      })

      it('calls the provided onAssignmentPostPolicyUpdated function', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(context.onAssignmentPostPolicyUpdated).toHaveBeenCalled()
        })
      })

      it('passes the assignmentId to onAssignmentPostPolicyUpdated', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(context.onAssignmentPostPolicyUpdated).toHaveBeenCalledWith(
            expect.objectContaining({
              assignmentId: '2301',
            }),
          )
        })
      })

      it('passes the postManually value to onAssignmentPostPolicyUpdated', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(context.onAssignmentPostPolicyUpdated).toHaveBeenCalledWith(
            expect.objectContaining({
              postManually: true,
            }),
          )
        })
      })
    })

    describe('on failure', () => {
      beforeEach(() => {
        Api.setAssignmentPostPolicy.mockRejectedValue({error: 'oh no'})
      })

      it('renders an error alert', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
        })
      })

      it('the rendered error alert contains a message', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              message: 'An error occurred while saving the assignment post policy',
            }),
          )
        })
      })

      it('the tray remains open', async () => {
        await userEvent.click(getButton('Save'))
        await waitFor(() => {
          expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
        })
        expect(getTray()).toBeInTheDocument()
      })
    })
  })
})
