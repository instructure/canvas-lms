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

import AssignmentPostingPolicyTray from '../index'
import * as Api from '../Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import { CamelizedAssignment } from '@canvas/grading/grading'
import fakeENV from '@canvas/test-utils/fakeENV'
import {MockedProvider} from '@apollo/client/testing'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('../Api')

type MockContext = {
  assignment: CamelizedAssignment
  selectedPostManually?: boolean
  onAssignmentPostPolicyUpdated?: ({
    assignmentId,
    postManually,
  }: {
    assignmentId: string
    postManually: boolean
  }) => void
   onExited?: () => void
  onDismiss?: () => void
}

describe('AssignmentPostingPolicyTray', () => {
  let context: MockContext
  let tray: AssignmentPostingPolicyTray | null = null

  const renderTray = () => {
    const component = render(
      <MockedProvider mocks={[]} addTypename={false}>
        <MockedQueryClientProvider client={queryClient}>
          <AssignmentPostingPolicyTray ref={ref => (tray = ref)} />
        </MockedQueryClientProvider>
      </MockedProvider>
    )
    tray?.show(context)
    return component
  }

  const getTray = () => screen.queryByTestId('assignment-posting-policy-tray')

  const getSaveButton = () => screen.getByTestId('assignment-posting-policy-save-button')
  const getCancelButton = () => screen.getByTestId('assignment-posting-policy-cancel-button')
  const getCloseButton = () => screen.getByTestId('assignment-posting-policy-close-button').children[0]
  const getInput = (name: string) => {
    return name === "Automatically" 
      ? screen.getByTestId('assignment-posting-policy-automatic-radio') 
      : screen.getByTestId('assignment-posting-policy-manual-radio')
  }

  beforeEach(() => {
    context = {
      assignment: {
        allowedAttempts: 1,
        anonymizeStudents: false,
        anonymousGrading: false,
        courseId: '1234',
        gradingType: 'points',
        id: '2301',
        name: 'Math 1.1',
        postManually: false,
        moderatedGrading: false,
        gradesPublished: false,
        dueAt: '',
        htmlUrl: 'http://example.com',
        muted: false,
        pointsPossible: 100,
        published: true,
        hasRubric: false,
        submissionTypes: ['online_text_entry'],
      },
      onAssignmentPostPolicyUpdated: jest.fn(),
      onExited: jest.fn(),
      onDismiss: jest.fn(),
    }

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
    jest.clearAllMocks()
  })

  describe('#show()', () => {
    it('opens the tray', async () => {
      renderTray()
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('includes the name of the assignment', async () => {
      renderTray()
      await waitFor(() => {
        expect(screen.getByText('Grade Posting Policy: Math 1.1')).toBeInTheDocument()
      })
    })

    it('disables the "Automatically" input for an anonymous assignment', async () => {
      context.assignment.anonymousGrading = true
      renderTray()
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
        await waitFor(() => {
          expect(getInput('Automatically')).toBeDisabled()
        })
      })

      it('enables the "Automatically" input when grades are published', async () => {
        context.assignment.gradesPublished = true
        renderTray()  
        await waitFor(() => {
          expect(getInput('Automatically')).toBeEnabled()
        })
      })

      it('always disables the "Automatically" input when the assignment is anonymous', async () => {
        context.assignment.anonymousGrading = true
        context.assignment.gradesPublished = true
        renderTray()  
        await waitFor(() => {
          expect(getInput('Automatically')).toBeDisabled()
        })
      })
    })

    it('enables the "Automatically" input if the assignment is not anonymous or moderated', async () => {
      renderTray()
      await waitFor(() => {
        expect(getInput('Automatically')).toBeEnabled()
      })
    })

    it('the "Automatically" input is initially selected if an auto-posted assignment is passed', async () => {
      renderTray()
      await waitFor(() => {
        expect(getInput('Automatically')).toBeChecked()
      })
    })

    it('the "Manually" input is initially selected if a manual-posted assignment is passed', async () => {
      context.assignment.postManually = true
      renderTray()
      await waitFor(() => {
        expect(getInput('Manually')).toBeChecked()
      })
    })

    it('enables the "Save" button if the postManually value has changed and no request is in progress', async () => {
      renderTray()
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
      expect(getSaveButton()).toBeEnabled()
    })

    it('disables the "Save" button if the postManually value has not changed', async () => {
      renderTray()
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

      renderTray()
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
      await userEvent.click(getSaveButton())
      expect(getSaveButton()).toBeDisabled()
      // @ts-expect-error
      resolveRequest()
    })
  })

  describe('"Close" Button', () => {
    beforeEach(async () => {
      renderTray()
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('closes the tray', async () => {
      await userEvent.click(getCloseButton())
      await waitFor(() => {
        expect(getTray()).not.toBeInTheDocument()
      })
    })
  })

  describe('"Cancel" button', () => {
    beforeEach(async () => {
      renderTray()
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('closes the tray', async () => {
      await userEvent.click(getCancelButton())
      await waitFor(() => {
        expect(getTray()).not.toBeInTheDocument()
      })
    })

    it('is enabled when no request is in progress', () => {
      expect(getCancelButton()).toBeEnabled()
    })

    it('is disabled when a request is in progress', async () => {
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

      await userEvent.click(getInput('Manually'))
      await userEvent.click(getSaveButton())
      expect(getCancelButton()).toBeDisabled()
      // @ts-expect-error
      resolveRequest()
    })
  })

  describe('"Save" button', () => {
    beforeEach(async () => {
      // @ts-expect-error
      Api.setAssignmentPostPolicy.mockResolvedValue({
        assignmentId: '2301',
        postManually: true,
      })

      renderTray()
      await waitFor(() => expect(getTray()).toBeInTheDocument())
      await userEvent.click(getInput('Manually'))
    })

    afterEach(() => {
      FlashAlert.destroyContainer()
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

  describe('ScheduledReleasePolicy tests', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          scheduled_feedback_releases: true,
        },
      })
      context.assignment.postManually = true
      context.selectedPostManually = false

      queryClient.setQueryData(['assignment_post_policy', context.assignment.id], null)
    })

    const enterNewDateTime = async(dateTimeElement: HTMLElement, dateTimeString: string) => {
      await userEvent.click(dateTimeElement)
      await userEvent.clear(dateTimeElement)
      await userEvent.paste(dateTimeString)
      await userEvent.tab()
    }

    it('renders the ScheduledReleasePolicy component when selectedPostManually is true', async () => {
      const { getByTestId } = renderTray()

      expect(getByTestId('scheduled-release-policy')).toBeInTheDocument()
    })

    it('displays the scheduled release options when the scheduled release checkbox is checked', async () => {
      const { getByTestId } = renderTray()
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
      const { getByTestId } = renderTray()
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
      const { getByTestId } = renderTray()
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
      const { getByTestId } = renderTray()
      const checkbox = getByTestId('scheduled-release-checkbox')

      // Enable scheduled release options
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()

      const saveButton = getSaveButton()
      expect(saveButton).toBeDisabled()
    })

    it('enables the "Save" button if scheduled post is selected and valid dates are set', async () => {
      const { getByTestId, getByPlaceholderText } = renderTray()
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

      const saveButton = getByTestId('assignment-posting-policy-save-button')
      expect(saveButton).toBeEnabled()
    })

    it('disables the "Save" button and displays error message if scheduled post dates are in the past', async () => {
      const { getByTestId, getByPlaceholderText } = renderTray()
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
      expect(saveButton).toBeDisabled()
      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()
    })

    it('enables the "Save" button if scheduled post is selected and valid separate dates are set', async () => {
      const { getByTestId, getAllByPlaceholderText } = renderTray()
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
      
      const saveButton = getByTestId('assignment-posting-policy-save-button')
      expect(saveButton).toBeEnabled()
    })

    it('disables the "Save" button and displays error messages if separate scheduled post dates are invalid', async () => {
      const { getByTestId, getAllByPlaceholderText } = renderTray()
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
      expect(saveButton).toBeDisabled()
      expect(screen.getAllByText('Date must be in the future')).toHaveLength(2)
    })

    it('disables the "Save" button and displays error messages if the comment release date is after the grade release date', async () => {
      const { getByTestId, getAllByPlaceholderText } = renderTray()
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
      expect(saveButton).toBeDisabled()
      expect(screen.getByText('Grades release date must be the same or after comments release date')).toBeInTheDocument()
      expect(screen.getByText('Comments release date must be the same or before grades release date')).toBeInTheDocument()
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

      const { getAllByPlaceholderText, getByTestId } = renderTray()

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

      const { getAllByPlaceholderText } = renderTray()

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

      const { getAllByPlaceholderText } = renderTray()

      const dateInputs = getAllByPlaceholderText('Select Date')
      expect(dateInputs).toHaveLength(2)

      // First, set comments date to a past date to trigger an error
      const pastCommentsDate = new Date()
      pastCommentsDate.setDate(pastCommentsDate.getDate() - 1)
      const pastCommentsDateString = pastCommentsDate.toISOString().slice(0, 16)

      await enterNewDateTime(dateInputs[1], pastCommentsDateString)

      // Verify the error appears
      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()

      // Now change the grades date to a valid future date
      const futureGradesDate = new Date()
      futureGradesDate.setDate(futureGradesDate.getDate() + 1)
      const futureGradesDateString = futureGradesDate.toISOString().slice(0, 16)

      await enterNewDateTime(dateInputs[0], futureGradesDateString)

      // The comments error should still be present
      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()
    })
  })
})
