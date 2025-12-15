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

import {waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import * as Api from '../Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {
  MockContext,
  createDefaultContext,
  renderTray,
  getTray,
  getSaveButton,
  getCloseButton,
  getInput,
} from './AssignmentPostingPolicyTrayTestUtils'

vi.mock('@canvas/alerts/react/FlashAlert')
vi.mock('../Api')

describe('AssignmentPostingPolicyTray "Save" button', () => {
  let context: MockContext

  beforeEach(async () => {
    context = createDefaultContext()

    // @ts-expect-error
    FlashAlert.showFlashAlert.mockReset()
    // @ts-expect-error
    Api.setAssignmentPostPolicy.mockReset()

    // @ts-expect-error
    Api.setAssignmentPostPolicy.mockResolvedValue({
      assignmentId: '2301',
      postManually: true,
    })

    renderTray(context)
    await waitFor(() => expect(getTray()).toBeInTheDocument())
    await userEvent.click(getInput('Manually'))
  })

  afterEach(async () => {
    FlashAlert.destroyContainer()
    if (getTray()) {
      await userEvent.click(getCloseButton())
      await waitFor(() => expect(context.onExited).toHaveBeenCalled())
    }
    vi.clearAllMocks()
  })

  it('calls setAssignmentPostPolicy', async () => {
    await userEvent.click(getSaveButton())
    expect(Api.setAssignmentPostPolicy).toHaveBeenCalled()
  })

  it('passes the assignment ID to setAssignmentPostPolicy', async () => {
    await userEvent.click(getSaveButton())
    expect(Api.setAssignmentPostPolicy).toHaveBeenCalledWith(
      expect.objectContaining({
        assignmentId: '2301',
      }),
    )
  })

  it('passes the selected postManually value to setAssignmentPostPolicy', async () => {
    await userEvent.click(getSaveButton())
    expect(Api.setAssignmentPostPolicy).toHaveBeenCalledWith(
      expect.objectContaining({
        postManually: true,
      }),
    )
  })

  describe('on success', () => {
    it('renders a success alert', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
      })
    })

    it('the rendered alert includes a message referencing the assignment', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Success! The post policy for Math 1.1 has been updated.',
          }),
        )
      })
    })

    it('calls the provided onAssignmentPostPolicyUpdated function', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(context.onAssignmentPostPolicyUpdated).toHaveBeenCalled()
      })
    })

    it('passes the assignmentId to onAssignmentPostPolicyUpdated', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(context.onAssignmentPostPolicyUpdated).toHaveBeenCalledWith(
          expect.objectContaining({
            assignmentId: '2301',
          }),
        )
      })
    })

    it('passes the postManually value to onAssignmentPostPolicyUpdated', async () => {
      await userEvent.click(getSaveButton())
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
      // @ts-expect-error
      Api.setAssignmentPostPolicy.mockRejectedValue({error: 'oh no'})
    })

    it('renders an error alert', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
      })
    })

    it('the rendered error alert contains a message', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'An error occurred while saving the assignment post policy',
          }),
        )
      })
    })

    it('the tray remains open', async () => {
      await userEvent.click(getSaveButton())
      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
      })
      expect(getTray()).toBeInTheDocument()
    })
  })
})
