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
import {render, fireEvent} from '@testing-library/react'
import CreateEditAssignmentModal, {
  type CreateEditAssignmentModalProps,
  type ModalAssignment,
} from '../CreateEditAssignmentModal'

jest.useFakeTimers().setSystemTime(new Date('2024-01-01T00:00:00Z'))

describe('CreateEditAssignmentModal', () => {
  let onCloseHandlerMock: jest.Mock
  let onSaveHandlerMock: jest.Mock
  let onMoreOptionsHandlerMock: jest.Mock

  const assignmentData: ModalAssignment = {
    type: 'none',
    name: 'Test Assignment',
    dueAt: '2024-01-14T00:00:00Z',
    unlockAt: '2024-01-12T00:00:00Z',
    lockAt: '2024-01-20T00:00:00Z',
    allDates: [],
    points: 100,
    isPublished: false,
    multipleDueDates: false,
    differentiatedAssignment: false,
    frozenFields: [],
  }

  const notGradedAssignmentData: ModalAssignment = {
    type: 'not_graded',
    name: 'Test Not Graded Assignment',
    dueAt: '2024-01-14T00:00:00Z',
    unlockAt: '2024-01-12T00:00:00Z',
    lockAt: '2024-01-20T00:00:00Z',
    allDates: [],
    points: 0,
    isPublished: false,
    multipleDueDates: false,
    differentiatedAssignment: false,
    frozenFields: [],
  }

  const defaultProps = (overrides: object = {}): CreateEditAssignmentModalProps => ({
    assignment: undefined,
    userIsAdmin: true,
    onCloseHandler: onCloseHandlerMock,
    onSaveHandler: onSaveHandlerMock,
    onMoreOptionsHandler: onMoreOptionsHandlerMock,
    timezone: 'UTC',
    validDueAtRange: {},
    defaultDueTime: '23:59',
    dueDateRequired: false,
    maxNameLength: 255,
    minNameLength: 1,
    syncGradesToSISFF: false,
    shouldSyncGradesToSIS: false,
    courseHasGradingPeriods: false,
    activeGradingPeriods: [],
    ...overrides,
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    onSaveHandlerMock = jest.fn()
    onMoreOptionsHandlerMock = jest.fn()
  })

  it('calls onCloseHandler when close button is clicked', () => {
    const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

    fireEvent.click(getByTestId('close-button'))
    expect(onCloseHandlerMock).toHaveBeenCalled()
  })

  it('calls onMoreOptionsHandler with form data when more options button is clicked', () => {
    const {getByTestId, getByPlaceholderText, getByText} = render(
      <CreateEditAssignmentModal {...defaultProps({assignment: assignmentData})} />,
    )

    fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
    fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})

    fireEvent.click(getByPlaceholderText('Choose a date'))
    fireEvent.click(getByText('15'))
    jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

    fireEvent.click(getByTestId('more-options-button'))

    expect(onMoreOptionsHandlerMock).toHaveBeenCalledWith(
      {
        type: 'none',
        name: 'Test Assignment',
        dueAt: '2024-01-15T00:00:00.000Z',
        points: 100,
        syncToSIS: false,
      },
      false,
    )
  })

  it('renders error messages when invalid input is present', () => {
    const {getByTestId, getByText} = render(<CreateEditAssignmentModal {...defaultProps()} />)

    fireEvent.change(getByTestId('assignment-name-input'), {target: {value: ''}})
    fireEvent.click(getByTestId('save-button'))

    expect(getByText('Please enter a name.')).toBeInTheDocument()
    expect(getByTestId('assignment-name-input')).toHaveFocus()
  })

  it('renders proper error messages in "Name" field when character limits are exceeded', () => {
    const overrides = {
      maxNameLength: 5,
      minNameLength: 3,
    }
    const {getByTestId, getByText} = render(
      <CreateEditAssignmentModal {...defaultProps(overrides)} />,
    )

    fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
    fireEvent.click(getByTestId('save-button'))
    expect(getByText('Name cannot exceed 5 characters.')).toBeInTheDocument()

    fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Hi'}})
    fireEvent.click(getByTestId('save-button'))
    expect(getByText('Name must be at least 3 characters.')).toBeInTheDocument()
  })

  it('renders proper error messages in "Points" field', () => {
    const {getByTestId, getByText} = render(<CreateEditAssignmentModal {...defaultProps()} />)

    fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
    fireEvent.change(getByTestId('points-input'), {target: {value: '-1'}})
    fireEvent.click(getByTestId('save-button'))
    expect(getByText('Points must be zero or greater.')).toBeInTheDocument()
    expect(getByTestId('points-input')).toHaveFocus()

    fireEvent.change(getByTestId('points-input'), {target: {value: '1000000000'}})
    fireEvent.click(getByTestId('save-button'))
    expect(getByText('Points cannot exceed 999,999,999.')).toBeInTheDocument()
  })

  describe('create mode', () => {
    it('renders correct components in create mode', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      expect(getByTestId('modal-title')).toBeInTheDocument()
      expect(getByTestId('close-button')).toBeInTheDocument()
      expect(getByTestId('assignment-type-select')).toBeInTheDocument()
      expect(getByTestId('assignment-name-input')).toBeInTheDocument()
      expect(getByTestId('due-date-container')).toBeInTheDocument()
      expect(getByTestId('points-input')).toBeInTheDocument()
      expect(getByTestId('save-button')).toBeInTheDocument()
      expect(getByTestId('more-options-button')).toBeInTheDocument()
      expect(getByTestId('save-and-publish-button')).toBeInTheDocument()
    })

    it('renders "Sync To SIS" toggle when passed into modal props', () => {
      const overrides = {
        syncGradesToSISFF: true,
        shouldSyncGradesToSIS: true,
      }
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps(overrides)} />)

      const toggle = getByTestId('sync-sis-toggle')
      expect(toggle).toBeInTheDocument()
      expect(toggle).toBeChecked()
    })

    it('can select different assignment types', () => {
      const {getByTestId, getAllByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps()} />,
      )

      fireEvent.click(getByTestId('assignment-type-select'))
      fireEvent.click(getAllByTestId('assignment-type-option')[1])

      expect(getByTestId('assignment-type-select')).toHaveValue('Discussion')

      fireEvent.click(getByTestId('assignment-type-select'))
      fireEvent.click(getAllByTestId('assignment-type-option')[2])

      expect(getByTestId('assignment-type-select')).toHaveValue('Quiz')
    })

    it('hides points input when selecting not_graded assignment type and saves with 0 points', () => {
      const {queryByTestId, getByTestId, getAllByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps()} />,
      )

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})
      fireEvent.click(getByTestId('assignment-type-select'))
      fireEvent.click(getAllByTestId('assignment-type-option')[4])

      expect(getByTestId('assignment-type-select')).toHaveValue('Not Graded')

      expect(queryByTestId('points-input')).not.toBeInTheDocument()
      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'not_graded',
          name: 'Test Assignment',
          dueAt: '',
          points: 0,
          publish: false,
          syncToSIS: false,
        },
        true,
      )
    })

    it('does not populate fields with assignment data in create mode', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      expect(getByTestId('assignment-name-input')).toHaveValue('')
      expect(getByTestId('points-input')).toHaveValue(0)
    })

    it('prevents saving when required fields are empty', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      const saveButton = getByTestId('save-button')
      const saveAndPublishButton = getByTestId('save-and-publish-button')

      fireEvent.click(saveButton)
      fireEvent.click(saveAndPublishButton)

      expect(onSaveHandlerMock).not.toHaveBeenCalled()
    })

    it('calls onSaveHandler with correct data when save button is clicked', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})
      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '',
          points: 100,
          publish: false,
          syncToSIS: false,
        },
        true,
      )
    })

    it('calls onSaveHandler with correct data when save and publish button is clicked', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})
      fireEvent.click(getByTestId('save-and-publish-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '',
          points: 100,
          publish: true,
          syncToSIS: false,
        },
        true,
      )
    })

    it('sets time to 11:59 PM when date is selected (and no time is present)', () => {
      const {getByTestId, getByPlaceholderText, getByText} = render(
        <CreateEditAssignmentModal {...defaultProps()} />,
      )

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})

      // open the calendar picker (Select January 15th)
      fireEvent.click(getByPlaceholderText('Choose a date'))
      fireEvent.click(getByText('15'))
      jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event
      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '2024-01-15T23:59:00.000Z',
          points: 100,
          publish: false,
          syncToSIS: false,
        },
        true,
      )
    })

    it('set time to DEFAULT_DUE_TIME if provided by props', () => {
      const {getByTestId, getByPlaceholderText, getByText} = render(
        <CreateEditAssignmentModal {...defaultProps({defaultDueTime: '03:00'})} />,
      )

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '100'}})

      // open the calendar picker (Select January 15th)
      fireEvent.click(getByPlaceholderText('Choose a date'))
      fireEvent.click(getByText('15'))
      jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '2024-01-15T03:00:00.000Z',
          points: 100,
          publish: false,
          syncToSIS: false,
        },
        true,
      )
    })

    it('allows saving when point input contains decimal values', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '35.35'}})
      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '',
          points: 35.35,
          publish: false,
          syncToSIS: false,
        },
        true,
      )
    })

    it('allows users to enter "0" for points input', () => {
      const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps()} />)

      fireEvent.change(getByTestId('assignment-name-input'), {target: {value: 'Test Assignment'}})
      fireEvent.change(getByTestId('points-input'), {target: {value: '0'}})
      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '',
          points: 0,
          publish: false,
          syncToSIS: false,
        },
        true,
      )
    })

    it('does not display points input field when type is not_graded', () => {
      const {queryByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment: notGradedAssignmentData})} />,
      )
      expect(queryByTestId('points-input')).not.toBeInTheDocument()
    })
  })

  describe('edit mode', () => {
    it('does not render assignment type field in edit mode', () => {
      const {queryByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment: assignmentData})} />,
      )

      expect(queryByTestId('assignment-type-select')).not.toBeInTheDocument()
    })

    it('populates fields with assignment data in edit mode', () => {
      const {getByTestId, getAllByText} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment: assignmentData})} />,
      )

      expect(getByTestId('assignment-name-input')).toHaveValue('Test Assignment')
      expect(getAllByText('Sunday, January 14, 2024 12:00 AM')[0]).toBeInTheDocument()
      expect(getByTestId('points-input')).toHaveValue(100)
    })

    it('save buttons are enabled when required fields are populated', () => {
      const {getByTestId} = render(
        <CreateEditAssignmentModal
          {...defaultProps({assignment: assignmentData, isEditMode: true})}
        />,
      )

      const saveButton = getByTestId('save-button')
      const saveAndPublishButton = getByTestId('save-and-publish-button')

      expect(saveButton).not.toBeDisabled()
      expect(saveAndPublishButton).not.toBeDisabled()
    })

    it('does not render "Save and Publish" button when assignment is already published', () => {
      const assignment = {...assignmentData, isPublished: true}
      const {queryByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment, isEditMode: true})} />,
      )

      expect(queryByTestId('save-and-publish-button')).not.toBeInTheDocument()
    })

    it('Does not change due date time when selecting new date if one was already present', () => {
      const {getByTestId, getByPlaceholderText, getByText} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment: assignmentData})} />,
      )

      // open the calendar picker (Select January 15th)
      fireEvent.click(getByPlaceholderText('Choose a date'))
      fireEvent.click(getByText('15'))
      jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '2024-01-15T00:00:00.000Z',
          points: 100,
          publish: false,
          syncToSIS: false,
        },
        false,
      )
    })

    it('Default due time Does not overwrite due date time if time is already present', () => {
      const assignment = {...assignmentData, dueAt: '2024-01-14T23:00:00Z'}
      const {getByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment, defaultDueTime: '03:00'})} />,
      )

      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'none',
          name: 'Test Assignment',
          dueAt: '2024-01-14T23:00:00Z',
          points: 100,
          publish: false,
          syncToSIS: false,
        },
        false,
      )
    })

    it('preserves submission type when editing an assignment', () => {
      const assignment = {...assignmentData, type: 'online_upload'}
      const {getByTestId} = render(
        <CreateEditAssignmentModal {...defaultProps({assignment, isEditMode: true})} />,
      )

      fireEvent.click(getByTestId('save-button'))

      expect(onSaveHandlerMock).toHaveBeenCalledWith(
        {
          type: 'online_upload',
          name: 'Test Assignment',
          dueAt: '2024-01-14T00:00:00Z',
          points: 100,
          publish: false,
          syncToSIS: false,
        },
        false,
      )
    })

    describe('Due Date Validation', () => {
      const termDates = {
        start_at: {date: '2024-01-12T00:00:00Z', date_context: 'term'},
        end_at: {date: '2024-01-20T00:00:00Z', date_context: 'term'},
      }
      const assignmentWithoutLocks: ModalAssignment = {
        ...assignmentData,
        lockAt: undefined,
        unlockAt: undefined,
      }

      it('Renders error message when due date is past assignment lock date', () => {
        const {getByPlaceholderText, getByText, getAllByText, getByTestId} = render(
          <CreateEditAssignmentModal {...defaultProps({assignment: assignmentData})} />,
        )

        // open calendar picker and select a date past the lock date
        const datePicker = getByPlaceholderText('Choose a date')
        fireEvent.click(datePicker)
        fireEvent.click(getByText('21'))
        jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

        // Try to save
        fireEvent.click(getByTestId('save-button'))

        expect(getAllByText('Due date cannot be after lock date')[0]).toBeInTheDocument()
        expect(datePicker).toHaveFocus()
      })

      it('Renders error message when due date is before assignment unlock date', () => {
        const {getByPlaceholderText, getByText, getAllByText, getByTestId} = render(
          <CreateEditAssignmentModal {...defaultProps({assignment: assignmentData})} />,
        )

        // open calendar picker and select a date before the unlock date
        const datePicker = getByPlaceholderText('Choose a date')
        fireEvent.click(datePicker)
        fireEvent.click(getByText('11'))
        jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

        // Try to save
        fireEvent.click(getByTestId('save-button'))

        expect(getAllByText('Due date cannot be before unlock date')[0]).toBeInTheDocument()
        expect(datePicker).toHaveFocus()
      })

      it('Renders error message when due date is past term end date', () => {
        const {getByPlaceholderText, getByText, getAllByText, getByTestId} = render(
          <CreateEditAssignmentModal
            {...defaultProps({assignment: assignmentWithoutLocks, validDueAtRange: termDates})}
          />,
        )

        // open calendar picker and select a date past the term end date
        const datePicker = getByPlaceholderText('Choose a date')
        fireEvent.click(datePicker)
        fireEvent.click(getByText('21'))
        jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

        // Try to save
        fireEvent.click(getByTestId('save-button'))

        expect(getAllByText('Due date cannot be after term end')[0]).toBeInTheDocument()
        expect(datePicker).toHaveFocus()
      })

      it('Renders error message when due date is before term start date', () => {
        const {getByPlaceholderText, getByText, getAllByText, getByTestId} = render(
          <CreateEditAssignmentModal
            {...defaultProps({assignment: assignmentWithoutLocks, validDueAtRange: termDates})}
          />,
        )

        // open calendar picker and select a date past the term end date
        const datePicker = getByPlaceholderText('Choose a date')
        fireEvent.click(datePicker)
        fireEvent.click(getByText('11'))
        jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

        // Try to save
        fireEvent.click(getByTestId('save-button'))

        expect(getAllByText('Due date cannot be before term start')[0]).toBeInTheDocument()
        expect(datePicker).toHaveFocus()
      })
    })

    describe('frozenFields', () => {
      it('Displays "Multiple Due Dates" message when assignment has multiple due dates', () => {
        const assignment = {
          ...assignmentData,
          multipleDueDates: true,
          differentiatedAssignment: true,
        }
        const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps({assignment})} />)

        expect(getByTestId('multiple-due-dates-message')).toBeInTheDocument()
        expect(getByTestId('multiple-due-dates-message')).toBeDisabled()
      })

      it('Displays "Differentiated Due Date" message when assignment is differentiated', () => {
        const assignment = {...assignmentData, differentiatedAssignment: true}
        const {getByTestId} = render(<CreateEditAssignmentModal {...defaultProps({assignment})} />)

        expect(getByTestId('multiple-due-dates-message')).toBeInTheDocument()
        expect(getByTestId('multiple-due-dates-message')).toHaveValue('Differentiated Due Date')
        expect(getByTestId('multiple-due-dates-message')).toBeDisabled()
      })

      it('Disables fields when included in frozenFields', () => {
        const assignment = {...assignmentData, frozenFields: ['name', 'due_at', 'points']}
        const {getByTestId, getByLabelText} = render(
          <CreateEditAssignmentModal {...defaultProps({assignment})} />,
        )

        expect(getByTestId('assignment-name-input')).toBeDisabled()
        expect(getByLabelText('Date')).toBeDisabled()
        expect(getByLabelText('Time')).toBeDisabled()
        expect(getByTestId('points-input')).toBeDisabled()
      })
    })
  })
})
