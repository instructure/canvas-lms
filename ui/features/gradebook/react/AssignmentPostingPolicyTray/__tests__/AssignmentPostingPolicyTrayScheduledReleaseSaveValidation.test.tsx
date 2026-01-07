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
import fakeENV from '@canvas/test-utils/fakeENV'
import {queryClient} from '@canvas/query'
import {
  MockContext,
  createDefaultContext,
  renderTray,
  getTray,
  getSaveButton,
  getCloseButton,
  getInput,
  enterNewDateTime,
} from './AssignmentPostingPolicyTrayTestUtils'

vi.mock('@canvas/alerts/react/FlashAlert')
vi.mock('../Api')

describe('AssignmentPostingPolicyTray ScheduledRelease - Save Validation', () => {
  let context: MockContext

  beforeEach(() => {
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

    fakeENV.setup({
      FEATURES: {
        scheduled_feedback_releases: true,
      },
    })
    context.assignment.postManually = true
    context.selectedPostManually = false

    queryClient.setQueryData(['assignment_post_policy', context.assignment.id], null)
  })

  afterEach(async () => {
    if (getTray()) {
      await userEvent.click(getCloseButton())
      await waitFor(() => expect(context.onExited).toHaveBeenCalled())
    }
    vi.clearAllMocks()
  })

  it('prevents save and shows error when scheduled release is checked in shared mode but no date is entered', async () => {
    context.assignment.postManually = false
    const {getByTestId} = renderTray(context)
    await userEvent.click(getInput('Manually'))

    const checkbox = getByTestId('scheduled-release-checkbox')
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Shared mode should be selected by default
    const sharedRadio = getByTestId('shared-scheduled-post')
    expect(sharedRadio).toBeChecked()

    const saveButton = getSaveButton()
    expect(saveButton).toBeEnabled()
    await userEvent.click(saveButton)

    expect(screen.getByText('Please enter a valid grades release date')).toBeInTheDocument()
    expect(Api.setAssignmentPostPolicy).not.toHaveBeenCalled()
  })

  it('prevents save and shows error when scheduled release is checked in separate mode but no dates are entered', async () => {
    context.assignment.postManually = false
    const {getByTestId} = renderTray(context)
    await userEvent.click(getInput('Manually'))
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Select separate mode
    const separateRadio = getByTestId('separate-scheduled-post')
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    const saveButton = getSaveButton()
    expect(saveButton).toBeEnabled()
    await userEvent.click(saveButton)

    const errorMessages = screen.getAllByText(/Please enter a valid (grades|comment) release date/)
    expect(errorMessages).toHaveLength(2)
    expect(Api.setAssignmentPostPolicy).not.toHaveBeenCalled()
  })

  it('prevents save and shows error when scheduled release is in separate mode and only grades date is entered', async () => {
    const {getByTestId, getAllByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Select separate mode
    const separateRadio = getByTestId('separate-scheduled-post')
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Enter only grades date
    const dateInputs = getAllByPlaceholderText('Select Date')
    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[0], futureDateString)

    const saveButton = getSaveButton()
    // Wait for state to settle after date entry
    await waitFor(() => {
      expect(saveButton).toBeEnabled()
    })
    await userEvent.click(saveButton)

    expect(screen.getByText('Please enter a valid comment release date')).toBeInTheDocument()
    expect(Api.setAssignmentPostPolicy).not.toHaveBeenCalled()
  })

  it('prevents save and shows error when scheduled release is in separate mode and only comments date is entered', async () => {
    const {getByTestId, getAllByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Select separate mode
    const separateRadio = getByTestId('separate-scheduled-post')
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Enter only comments date
    const dateInputs = getAllByPlaceholderText('Select Date')
    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[1], futureDateString)

    const saveButton = getSaveButton()
    // Wait for state to settle after date entry
    await waitFor(() => {
      expect(saveButton).toBeEnabled()
    })
    await userEvent.click(saveButton)

    expect(screen.getByText('Please enter a valid grades release date')).toBeInTheDocument()

    expect(Api.setAssignmentPostPolicy).not.toHaveBeenCalled()
  }, 10000)

  it('allows save when scheduled release is checked in shared mode and valid date is entered', async () => {
    const {getByTestId, getByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Shared mode should be selected by default
    const sharedRadio = getByTestId('shared-scheduled-post')
    expect(sharedRadio).toBeChecked()

    // Enter a valid future date
    const sharedDateInput = getByPlaceholderText('Choose release date')
    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString().slice(0, 16)

    await enterNewDateTime(sharedDateInput, futureDateString)

    const saveButton = getSaveButton()
    await userEvent.click(saveButton)

    expect(screen.queryByText('Please enter a valid grades release date')).not.toBeInTheDocument()

    await waitFor(() => {
      expect(Api.setAssignmentPostPolicy).toHaveBeenCalled()
    })
  })

  it('allows save when scheduled release is checked in separate mode and both valid dates are entered', async () => {
    const {getByTestId, getAllByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Select separate mode
    const separateRadio = getByTestId('separate-scheduled-post')
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Enter valid future dates for both fields
    const dateInputs = getAllByPlaceholderText('Select Date')
    const futureDate1 = new Date()
    futureDate1.setDate(futureDate1.getDate() + 1)
    const futureDateString1 = futureDate1.toISOString().slice(0, 16)

    const futureDate2 = new Date()
    futureDate2.setDate(futureDate2.getDate() + 1)
    const futureDateString2 = futureDate2.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[0], futureDateString1)
    await enterNewDateTime(dateInputs[1], futureDateString2)

    const saveButton = getSaveButton()
    await userEvent.click(saveButton)

    expect(screen.queryByText('Please enter a valid grades release date')).not.toBeInTheDocument()
    expect(screen.queryByText('Please enter a valid comment release date')).not.toBeInTheDocument()

    await waitFor(() => {
      expect(Api.setAssignmentPostPolicy).toHaveBeenCalled()
    })
  })

  it('allows save when scheduled release is not checked', async () => {
    context.assignment.postManually = false
    renderTray(context)
    await waitFor(() => expect(getTray()).toBeInTheDocument())
    await userEvent.click(getInput('Manually'))

    const checkbox = screen.getByTestId('scheduled-release-checkbox')
    expect(checkbox).not.toBeChecked()

    const saveButton = getSaveButton()
    expect(saveButton).toBeEnabled()
    await userEvent.click(saveButton)
    await waitFor(() => {
      expect(Api.setAssignmentPostPolicy).toHaveBeenCalled()
    })
  })
})
