/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import SaveAlert, {SaveAlertProps} from '../SaveAlert'
import {Alert as AlertData, CriterionType} from '../types'
import {calculateUIMetadata} from '../utils'
import userEvent from '@testing-library/user-event'
import {alert, accountRole} from './helpers'

describe('SaveAlert', () => {
  const getProps = (): SaveAlertProps => {
    return {
      initialAlert: structuredClone(alert),
      uiMetadata: calculateUIMetadata([accountRole]),
      isOpen: true,
      onClick: jest.fn(),
      onClose: jest.fn(),
      onSave: jest.fn(),
    }
  }

  it('should render the edit alert form correctly', () => {
    const props = getProps()
    render(<SaveAlert {...props} />)

    const tray = screen.getByLabelText('Edit Alert')
    const triggerSelect = within(tray).getByPlaceholderText('Select a trigger type')
    const noInteractionTrigger = within(tray).getByLabelText(
      /a teacher has not interacted with the student /i,
    )
    const ungradedSubmissionCountTrigger = within(tray).getByLabelText(
      /ungraded submissions exceed/i,
    )
    const ungradedSubmissionTimeTrigger = within(tray).getByLabelText(
      /a submission has been left ungraded for/i,
    )
    const sendToAccountAdmin = within(tray).getByLabelText('Account Admin')
    const sendToStudent = within(tray).getByLabelText('Student')
    const sendToTeacher = within(tray).getByLabelText('Teacher')
    const resendEvery = within(tray).getByLabelText('Resend every *')
    const doNotResend = within(tray).getByLabelText('Do not resend alerts')
    expect(triggerSelect).toHaveValue('')
    expect(noInteractionTrigger).toHaveValue(props.initialAlert?.criteria[0].threshold)
    expect(ungradedSubmissionCountTrigger).toHaveValue(props.initialAlert?.criteria[1].threshold)
    expect(ungradedSubmissionTimeTrigger).toHaveValue(props.initialAlert?.criteria[2].threshold)
    expect(sendToAccountAdmin).toBeChecked()
    expect(sendToStudent).toBeChecked()
    expect(sendToTeacher).toBeChecked()
    expect(resendEvery).toHaveValue(props.initialAlert?.repetition)
    expect(doNotResend).not.toBeChecked()
  })

  it('should call onSave correctly when editing an alert', async () => {
    const props = getProps()
    render(<SaveAlert {...props} />)

    const saveButton = screen.getByLabelText('Save Alert')
    await userEvent.click(saveButton)

    expect(props.onSave).toHaveBeenCalledWith({alert: props.initialAlert})
  })

  it('should create an alert and call onSave correctly', async () => {
    const props = getProps()
    render(<SaveAlert {...props} initialAlert={undefined} />)
    const triggerValue = '10'
    const resendEveryValue = '30'

    // Select and add a trigger
    const triggerSelect = screen.getByPlaceholderText(/select a trigger type/i)
    fireEvent.click(triggerSelect)
    const triggerOption = await screen.findByText('Ungraded Submissions (Count)')
    await userEvent.click(triggerOption)
    const addTriggerButton = screen.getByLabelText('Add trigger')
    await userEvent.click(addTriggerButton)
    // Modify the trigger value
    const ungradedSubmissionCountTrigger = screen.getByLabelText(/ungraded submissions exceed/i)
    await userEvent.clear(ungradedSubmissionCountTrigger)
    await userEvent.type(ungradedSubmissionCountTrigger, triggerValue)
    // Select send to options
    const sendToAccountAdmin = screen.getByLabelText('Account Admin')
    const sendToStudent = screen.getByLabelText('Student')
    await userEvent.click(sendToAccountAdmin)
    await userEvent.click(sendToStudent)
    // Deselect resend every option
    const doNotResend = screen.getByLabelText('Do not resend alerts')
    await userEvent.click(doNotResend)
    // Modify the resend every value
    const resendEvery = screen.getByLabelText('Resend every *')
    await userEvent.clear(resendEvery)
    await userEvent.type(resendEvery, resendEveryValue)
    // Save the alert
    const saveButton = screen.getByLabelText('Save Alert')
    await userEvent.click(saveButton)

    expect(props.onSave).toHaveBeenCalledWith({
      alert: {
        criteria: [
          {
            criterion_type: CriterionType.UngradedCount,
            threshold: Number(triggerValue),
          },
        ],
        id: undefined,
        recipients: [accountRole.id, ':student'],
        repetition: Number(resendEveryValue),
      },
    })
  })

  it('should call onClose when the close button is clicked', async () => {
    const props = getProps()
    render(<SaveAlert {...props} />)

    const closeButton = screen.getByLabelText('Cancel')
    await userEvent.click(closeButton)

    expect(props.onClose).toHaveBeenCalled()
  })

  it('should call the onClick when the "+ Alert" button is click', async () => {
    const props = getProps()
    render(<SaveAlert {...props} />)

    const button = screen.getByLabelText('Create new alert')
    await userEvent.click(button)

    expect(props.onClick).toHaveBeenCalled()
  })

  describe('Trigger when section', () => {
    it('should show an error message when no trigger is selected', async () => {
      const props = getProps()
      render(<SaveAlert {...props} initialAlert={undefined} />)

      const saveButton = screen.getByLabelText('Save Alert')
      await userEvent.click(saveButton)

      const errorText = screen.getByText('Please add at least one trigger.')
      expect(errorText).toBeInTheDocument()
    })

    it('should be able to add a trigger', async () => {
      const props = getProps()
      render(<SaveAlert {...props} initialAlert={undefined} />)

      const triggerSelect = screen.getByPlaceholderText(/select a trigger type/i)
      fireEvent.click(triggerSelect)
      const triggerOption = await screen.findByText('Ungraded Submissions (Count)')
      await userEvent.click(triggerOption)
      const addTriggerButton = screen.getByLabelText('Add trigger')
      await userEvent.click(addTriggerButton)

      const ungradedSubmissionCountTrigger = screen.getByLabelText(/ungraded submissions exceed/i)
      expect(ungradedSubmissionCountTrigger).toBeInTheDocument()
      expect(ungradedSubmissionCountTrigger).toHaveValue(props.initialAlert?.criteria[1].threshold)
    })

    it('should be able to remove a trigger', async () => {
      const props = getProps()
      render(<SaveAlert {...props} />)

      const ungradedSubmissionCountTriggerRemoveButton = screen.getByLabelText(
        'Remove Ungraded Submissions (Count)',
      )
      await userEvent.click(ungradedSubmissionCountTriggerRemoveButton)

      const ungradedSubmissionCountTriggerInput = screen.queryByLabelText(
        /ungraded submissions exceed/i,
      )
      const triggerSelect = screen.getByPlaceholderText('Select a trigger type')
      expect(ungradedSubmissionCountTriggerInput).not.toBeInTheDocument()
      expect(triggerSelect).toHaveValue('Ungraded Submissions (Count)')
    })

    it('should be able to enter a positive number to a trigger', async () => {
      const triggerValue = '10'
      const props = getProps()
      render(<SaveAlert {...props} />)

      const ungradedSubmissionCountTrigger = screen.getByLabelText(/ungraded submissions exceed/i)
      await userEvent.clear(ungradedSubmissionCountTrigger)
      await userEvent.type(ungradedSubmissionCountTrigger, triggerValue)

      await waitFor(() => {
        expect(ungradedSubmissionCountTrigger).toHaveValue(Number(triggerValue))
      })
    })

    it('should not be able to enter a less then 0 number to a trigger', async () => {
      const triggerValue = '-10'
      const defaultValue = 1
      const props = getProps()
      render(<SaveAlert {...props} />)

      const ungradedSubmissionCountTrigger = screen.getByLabelText(/ungraded submissions exceed/i)
      await userEvent.clear(ungradedSubmissionCountTrigger)
      await userEvent.type(ungradedSubmissionCountTrigger, triggerValue)
      await userEvent.tab()

      await waitFor(() => {
        expect(ungradedSubmissionCountTrigger).toHaveValue(defaultValue)
      })
    })
  })

  describe('Send to section', () => {
    it('should show an error message when no recipient is selected', async () => {
      const props = getProps()
      render(<SaveAlert {...props} initialAlert={undefined} />)

      const saveButton = screen.getByLabelText('Save Alert')
      await userEvent.click(saveButton)

      const errorText = screen.getAllByText('Please select at least one option.')
      expect(errorText.length).toBeTruthy()
    })
  })

  describe('Resend every section', () => {
    it('should be disabled if the "Do not resend alerts" option is selected', async () => {
      const props = getProps()
      render(
        <SaveAlert {...props} initialAlert={{...props.initialAlert, repetition: 0} as AlertData} />,
      )

      const resendEvery = screen.getByLabelText('Resend every *')
      expect(resendEvery).toBeDisabled()
    })

    it('should be enabled if the "Do not resend alerts" option is not selected', async () => {
      const props = getProps()
      render(<SaveAlert {...props} />)

      const resendEvery = screen.getByLabelText('Resend every *')
      expect(resendEvery).toBeEnabled()
    })

    it('should be able to enter a positive number to the resend every field', async () => {
      const resendEveryValue = '10'
      const props = getProps()
      render(<SaveAlert {...props} />)

      const resendEvery = screen.getByLabelText('Resend every *')
      await userEvent.clear(resendEvery)
      await userEvent.type(resendEvery, resendEveryValue)

      await waitFor(() => {
        expect(resendEvery).toHaveValue(Number(resendEveryValue))
      })
    })

    it('should not be able to enter a less then 0 number to the resend every field', async () => {
      const resendEveryValue = '-10'
      const defaultValue = 1
      const props = getProps()
      render(<SaveAlert {...props} />)

      const resendEvery = screen.getByLabelText('Resend every *')
      await userEvent.clear(resendEvery)
      await userEvent.type(resendEvery, resendEveryValue)
      await userEvent.tab()

      await waitFor(() => {
        expect(resendEvery).toHaveValue(defaultValue)
      })
    })
  })
})
