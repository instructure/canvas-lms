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

import {screen, waitFor} from '@testing-library/react'
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

describe('AssignmentPostingPolicyTray #show()', () => {
  let context: MockContext

  beforeEach(() => {
    context = createDefaultContext()

    // @ts-expect-error
    FlashAlert.showFlashAlert.mockReset()
    // @ts-expect-error
    Api.setAssignmentPostPolicy.mockReset()
  })

  afterEach(async () => {
    if (getTray()) {
      await userEvent.click(getCloseButton())
      await waitFor(() => expect(context.onExited).toHaveBeenCalled())
    }
    vi.clearAllMocks()
  })

  it('opens the tray', async () => {
    renderTray(context)
    await waitFor(() => expect(getTray()).toBeInTheDocument())
  })

  it('includes the name of the assignment', async () => {
    renderTray(context)
    await waitFor(() => {
      expect(screen.getByText('Grade Posting Policy: Math 1.1')).toBeInTheDocument()
    })
  })

  it('disables the "Automatically" input for an anonymous assignment', async () => {
    context.assignment.anonymousGrading = true
    renderTray(context)
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
      renderTray(context)
      await waitFor(() => {
        expect(getInput('Automatically')).toBeDisabled()
      })
    })

    it('enables the "Automatically" input when grades are published', async () => {
      context.assignment.gradesPublished = true
      renderTray(context)
      await waitFor(() => {
        expect(getInput('Automatically')).toBeEnabled()
      })
    })

    it('always disables the "Automatically" input when the assignment is anonymous', async () => {
      context.assignment.anonymousGrading = true
      context.assignment.gradesPublished = true
      renderTray(context)
      await waitFor(() => {
        expect(getInput('Automatically')).toBeDisabled()
      })
    })
  })

  it('enables the "Automatically" input if the assignment is not anonymous or moderated', async () => {
    renderTray(context)
    await waitFor(() => {
      expect(getInput('Automatically')).toBeEnabled()
    })
  })

  it('the "Automatically" input is initially selected if an auto-posted assignment is passed', async () => {
    renderTray(context)
    await waitFor(() => {
      expect(getInput('Automatically')).toBeChecked()
    })
  })

  it('the "Manually" input is initially selected if a manual-posted assignment is passed', async () => {
    context.assignment.postManually = true
    renderTray(context)
    await waitFor(() => {
      expect(getInput('Manually')).toBeChecked()
    })
  })

  it('enables the "Save" button if the postManually value has changed and no request is in progress', async () => {
    renderTray(context)
    await waitFor(() => expect(getTray()).toBeInTheDocument())
    await userEvent.click(getInput('Manually'))
    expect(getSaveButton()).toBeEnabled()
  })

  it('disables the "Save" button if the postManually value has not changed', async () => {
    renderTray(context)
    await waitFor(() => expect(getTray()).toBeInTheDocument())
    await userEvent.click(getInput('Manually'))
    await userEvent.click(getInput('Automatically'))
    expect(getSaveButton()).toBeDisabled()
  })

  it('disables the "Save" button if a request is already in progress', async () => {
    let resolveRequest

    // @ts-expect-error
    Api.setAssignmentPostPolicy.mockImplementation(
      () =>
        new Promise(resolve => {
          resolveRequest = () => {
            resolve({assignmentId: '2301', postManually: true})
          }
        }),
    )

    renderTray(context)
    await waitFor(() => expect(getTray()).toBeInTheDocument())
    await userEvent.click(getInput('Manually'))
    await userEvent.click(getSaveButton())
    expect(getSaveButton()).toBeDisabled()
    // @ts-expect-error
    resolveRequest()
  })
})
