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

describe('AssignmentPostingPolicyTray ScheduledReleasePolicy tests', () => {
  let context: MockContext

  beforeEach(() => {
    context = createDefaultContext()

    // @ts-expect-error
    FlashAlert.showFlashAlert.mockReset()
    // @ts-expect-error
    Api.setAssignmentPostPolicy.mockReset()

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

  it('renders the ScheduledReleasePolicy component when selectedPostManually is true', async () => {
    const {getByTestId} = renderTray(context)

    expect(getByTestId('scheduled-release-policy')).toBeInTheDocument()
  })

  it('displays the scheduled release options when the scheduled release checkbox is checked', async () => {
    const {getByTestId} = renderTray(context)
    const scheduledReleasePolicy = getByTestId('scheduled-release-policy')

    const checkbox = getByTestId('scheduled-release-checkbox')
    expect(checkbox).toBeInTheDocument()
    expect(checkbox).not.toBeChecked()

    // Scheduled release options should not be visible initially
    expect(scheduledReleasePolicy).not.toHaveTextContent('Grades & Comments Together')
    expect(scheduledReleasePolicy).not.toHaveTextContent('Separate Schedules')

    // Check the checkbox to enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    // Now the scheduled release options should be visible
    expect(scheduledReleasePolicy).toHaveTextContent('Grades & Comments Together')
    expect(scheduledReleasePolicy).toHaveTextContent('Separate Schedules')
  })

  it('displays the date input for shared scheduled posts when "Grades & Comments Together" is selected', async () => {
    const {getByTestId} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const sharedRadio = getByTestId('shared-scheduled-post')
    expect(sharedRadio).toBeInTheDocument()

    // Check for the presence of the shared date input
    const sharedDateInput = getByTestId('shared-scheduled-post-datetime')
    expect(sharedDateInput).toBeInTheDocument()
  })

  it('displays the date inputs for separate scheduled posts when "Separate Schedules" is selected', async () => {
    const {getByTestId} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const separateRadio = getByTestId('separate-scheduled-post')
    expect(separateRadio).toBeInTheDocument()

    // Select the "Separate Schedules" option
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Check for the presence of the separate date inputs
    const gradesDateInput = getByTestId('separate-scheduled-post-datetime-grade')
    const commentsDateInput = getByTestId('separate-scheduled-post-datetime-comment')
    expect(gradesDateInput).toBeInTheDocument()
    expect(commentsDateInput).toBeInTheDocument()
  })

  it('disables the "Save" button if scheduled post is selected but no dates are set', async () => {
    const {getByTestId} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const saveButton = getSaveButton()
    expect(saveButton).toBeDisabled()
  })

  it('enables the "Save" button if scheduled post is selected and valid dates are set', async () => {
    const {getByTestId, getByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const sharedRadio = getByTestId('shared-scheduled-post')
    expect(sharedRadio).toBeInTheDocument()

    // Set a valid date in the shared date input
    const sharedDateInput = getByPlaceholderText('Choose release date')
    expect(sharedDateInput).toBeInTheDocument()

    // Input a future date
    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString().slice(0, 16) // Format as "YYYY-MM-DDTHH:MM"

    await enterNewDateTime(sharedDateInput, futureDateString)

    // Wait for state to update after date input
    await waitFor(() => {
      const saveButton = getByTestId('assignment-posting-policy-save-button')
      expect(saveButton).toBeEnabled()
    })
  })

  it('disables the "Save" button and displays error message if scheduled post dates are in the past', async () => {
    const {getByTestId, getByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const sharedRadio = getByTestId('shared-scheduled-post')
    expect(sharedRadio).toBeInTheDocument()

    // Set an invalid past date in the shared date input
    const sharedDateInput = getByPlaceholderText('Choose release date')
    expect(sharedDateInput).toBeInTheDocument()

    // Input a past date
    const pastDate = new Date()
    pastDate.setDate(pastDate.getDate() - 1)
    const pastDateString = pastDate.toISOString().slice(0, 16) // Format as "YYYY-MM-DDTHH:MM"

    await enterNewDateTime(sharedDateInput, pastDateString)

    const saveButton = getByTestId('assignment-posting-policy-save-button')
    await waitFor(() => {
      expect(saveButton).toBeDisabled()
      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()
    })
  })

  it('enables the "Save" button if scheduled post is selected and valid separate dates are set', async () => {
    const {getByTestId, getAllByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const separateRadio = getByTestId('separate-scheduled-post')
    expect(separateRadio).toBeInTheDocument()

    // Select the "Separate Schedules" option
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Set valid future dates in the separate date inputs
    const dateInputs = getAllByPlaceholderText('Select Date')
    expect(dateInputs).toHaveLength(2)

    // Input future dates
    const futureDate1 = new Date()
    futureDate1.setDate(futureDate1.getDate() + 1)
    const futureDateString1 = futureDate1.toISOString().slice(0, 16)

    const futureDate2 = new Date()
    futureDate2.setDate(futureDate2.getDate() + 1)
    const futureDateString2 = futureDate2.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[0], futureDateString1)
    await enterNewDateTime(dateInputs[1], futureDateString2)

    await waitFor(() => {
      const saveButton = getByTestId('assignment-posting-policy-save-button')
      expect(saveButton).toBeEnabled()
    })
  }, 10000)

  it('disables the "Save" button and displays error messages if separate scheduled post dates are invalid', async () => {
    const {getByTestId, getAllByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const separateRadio = getByTestId('separate-scheduled-post')
    expect(separateRadio).toBeInTheDocument()

    // Select the "Separate Schedules" option
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Set invalid past dates in the separate date inputs
    const dateInputs = getAllByPlaceholderText('Select Date')
    expect(dateInputs).toHaveLength(2)

    // Input past dates
    const pastDate1 = new Date()
    pastDate1.setDate(pastDate1.getDate() - 1)
    const pastDateString1 = pastDate1.toISOString().slice(0, 16)

    const pastDate2 = new Date()
    pastDate2.setDate(pastDate2.getDate() - 1)
    const pastDateString2 = pastDate2.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[0], pastDateString1) // Grade release date
    await enterNewDateTime(dateInputs[1], pastDateString2) // Comment release date

    const saveButton = getByTestId('assignment-posting-policy-save-button')
    await waitFor(() => {
      expect(saveButton).toBeDisabled()
      expect(screen.getAllByText('Date must be in the future')).toHaveLength(2)
    })
  })

  it('disables the "Save" button and displays error messages if the comment release date is after the grade release date', async () => {
    const {getByTestId, getAllByPlaceholderText} = renderTray(context)
    const checkbox = getByTestId('scheduled-release-checkbox')

    // Enable scheduled release options
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    const separateRadio = getByTestId('separate-scheduled-post')
    expect(separateRadio).toBeInTheDocument()

    // Select the "Separate Schedules" option
    await userEvent.click(separateRadio)
    expect(separateRadio).toBeChecked()

    // Set invalid separate dates where comment date is before grade date
    const dateInputs = getAllByPlaceholderText('Select Date')
    expect(dateInputs).toHaveLength(2)

    // Input dates where comments date is before grades date
    const futureDate1 = new Date()
    futureDate1.setDate(futureDate1.getDate() + 2)
    const futureDateString1 = futureDate1.toISOString().slice(0, 16)

    const futureDate2 = new Date()
    futureDate2.setDate(futureDate2.getDate() + 1)
    const futureDateString2 = futureDate2.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[1], futureDateString1)
    await enterNewDateTime(dateInputs[0], futureDateString2)

    const saveButton = getByTestId('assignment-posting-policy-save-button')
    await waitFor(() => {
      expect(saveButton).toBeDisabled()
      expect(
        screen.getByText('Grades release date must be the same or after comments release date'),
      ).toBeInTheDocument()
      expect(
        screen.getByText('Comments release date must be the same or before grades release date'),
      ).toBeInTheDocument()
    })
  })

  it('does not show validation error for pre-existing grades date when only comments date is changed', async () => {
    const pastDate = new Date()
    pastDate.setDate(pastDate.getDate() - 1)
    const pastDateString = pastDate.toISOString()

    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString()

    queryClient.setQueryData(['assignment_post_policy', context.assignment.id], {
      postGradesAt: pastDateString,
      postCommentsAt: futureDateString,
    })

    const {getAllByPlaceholderText, getByTestId} = renderTray(context)

    const dateInputs = getAllByPlaceholderText('Select Date')
    expect(dateInputs).toHaveLength(2)

    const futureCommentsDate = new Date()
    futureCommentsDate.setDate(futureCommentsDate.getDate() + 2)
    const futureCommentsDateString = futureCommentsDate.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[1], futureCommentsDateString)

    // The grades date should NOT show "Date must be in the future" error
    // because we only changed the comments date and had a pre-existing past grades date
    const errorMessages = screen.queryAllByText('Date must be in the future')
    expect(errorMessages).toHaveLength(0)
  })

  it('does not show validation error for past comments date when only grades date is changed', async () => {
    const pastDate = new Date()
    pastDate.setDate(pastDate.getDate() - 1)
    const pastDateString = pastDate.toISOString()

    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString()

    queryClient.setQueryData(['assignment_post_policy', context.assignment.id], {
      postGradesAt: futureDateString,
      postCommentsAt: pastDateString,
    })

    const {getAllByPlaceholderText} = renderTray(context)

    const dateInputs = getAllByPlaceholderText('Select Date')
    expect(dateInputs).toHaveLength(2)

    // Change only the grades date to a future date
    const futureGradesDate = new Date()
    futureGradesDate.setDate(futureGradesDate.getDate() + 2)
    const futureGradesDateString = futureGradesDate.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[0], futureGradesDateString)

    // The comments date should NOT show "Date must be in the future" error
    // because we only changed the grades date
    const errorMessages = screen.queryAllByText('Date must be in the future')
    expect(errorMessages).toHaveLength(0)
  })

  it('preserves existing validation errors when changing the other field', async () => {
    const pastDate = new Date()
    pastDate.setDate(pastDate.getDate() - 1)
    const pastDateString = pastDate.toISOString()

    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString()

    queryClient.setQueryData(['assignment_post_policy', context.assignment.id], {
      postGradesAt: futureDateString,
      postCommentsAt: pastDateString,
    })

    const {getAllByPlaceholderText} = renderTray(context)

    const dateInputs = getAllByPlaceholderText('Select Date')
    expect(dateInputs).toHaveLength(2)

    // First, set comments date to a past date to trigger an error
    const pastCommentsDate = new Date()
    pastCommentsDate.setDate(pastCommentsDate.getDate() - 1)
    const pastCommentsDateString = pastCommentsDate.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[1], pastCommentsDateString)

    // Verify the error appears
    await waitFor(() => {
      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()
    })

    // Now change the grades date to a valid future date
    const futureGradesDate = new Date()
    futureGradesDate.setDate(futureGradesDate.getDate() + 1)
    const futureGradesDateString = futureGradesDate.toISOString().slice(0, 16)

    await enterNewDateTime(dateInputs[0], futureGradesDateString)

    // The comments error should still be present
    await waitFor(() => {
      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()
    })
  })

  describe('validation on save', () => {
    beforeEach(() => {
      // @ts-expect-error
      Api.setAssignmentPostPolicy.mockResolvedValue({
        assignmentId: '2301',
        postManually: true,
      })
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

      const errorMessages = screen.getAllByText(
        /Please enter a valid (grades|comment) release date/,
      )
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

    it(
      'prevents save and shows error when scheduled release is in separate mode and only comments date is entered',
      async () => {
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
      },
      10000,
    )

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

      expect(
        screen.queryByText('Please enter a valid grades release date'),
      ).not.toBeInTheDocument()

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

      expect(
        screen.queryByText('Please enter a valid grades release date'),
      ).not.toBeInTheDocument()
      expect(
        screen.queryByText('Please enter a valid comment release date'),
      ).not.toBeInTheDocument()

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
})
