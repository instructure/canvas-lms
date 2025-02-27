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

import {render, screen} from '@testing-library/react'
import Alert, {AlertProps} from '../Alert'
import {AlertUIMetadata} from '../types'
import {calculateUIMetadata} from '../utils'
import userEvent from '@testing-library/user-event'
import {alert, accountRole} from './helpers'

describe('Alert', () => {
  const uiMetadata: AlertUIMetadata = calculateUIMetadata([accountRole])
  const props: AlertProps = {
    alert,
    uiMetadata,
    onEdit: jest.fn(),
    onDelete: jest.fn(),
  }

  it('should render the "Trigger when" section correctly', () => {
    render(<Alert {...props} />)

    alert.criteria.forEach(criterion => {
      const criterionType = uiMetadata.POSSIBLE_CRITERIA[criterion.criterion_type]
      const currentTriggerText = screen.getByText(criterionType.label(criterion.threshold))
      expect(currentTriggerText).toBeInTheDocument()
    })
  })

  it('should render the "Send to" section correctly', () => {
    render(<Alert {...props} />)

    alert.recipients.forEach(recipientId => {
      const currentRecipientText = screen.getByText(uiMetadata.POSSIBLE_RECIPIENTS[recipientId])
      expect(currentRecipientText).toBeInTheDocument()
    })
  })

  describe('when repetition is provided', () => {
    it('should render the "Resend alerts" section correctly', () => {
      render(<Alert {...props} />)

      const resendAlertText = screen.getByText(`Every ${alert.repetition} days until resolved.`)
      expect(resendAlertText).toBeInTheDocument()
    })
  })

  describe('when repetition is not provided', () => {
    it('should render the "Resend alerts" section correctly', () => {
      const alertWithoutRepetition = {...alert, repetition: 0}
      const propsWithoutRepetition: AlertProps = {
        ...props,
        alert: alertWithoutRepetition,
      }
      render(<Alert {...propsWithoutRepetition} />)

      const resendAlertText = screen.getByText('Do not resend.')
      expect(resendAlertText).toBeInTheDocument()
    })
  })

  it('should call onEdit when the edit button is clicked', async () => {
    render(<Alert {...props} />)

    const editButton = screen.getByLabelText('Edit alert button')
    await userEvent.click(editButton)

    expect(props.onEdit).toHaveBeenCalledWith(alert)
  })

  it('should call onDelete when the delete button is clicked', async () => {
    render(<Alert {...props} />)

    const deleteButton = screen.getByLabelText('Delete alert button')
    await userEvent.click(deleteButton)

    expect(props.onDelete).toHaveBeenCalledWith(alert)
  })
})
