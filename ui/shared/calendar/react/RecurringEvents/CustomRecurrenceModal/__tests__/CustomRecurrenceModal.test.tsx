/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import moment from 'moment-timezone'
import {render, fireEvent} from '@testing-library/react'
import type {UnknownSubset} from '../../types'
import CustomRecurrenceModal, {type CustomRecurrenceModalProps} from '../CustomRecurrenceModal'

const defaultTZ = 'Asia/Tokyo'

const defaultProps = (
  overrides: UnknownSubset<CustomRecurrenceModalProps> = {}
): CustomRecurrenceModalProps => ({
  eventStart: '2021-01-01T00:00:00.000Z',
  locale: 'en',
  timezone: defaultTZ,
  courseEndAt: undefined,
  RRULE: 'RRULE:FREQ=DAILY;INTERVAL=1;COUNT=5',
  isOpen: true,
  onClose: () => {},
  onDismiss: () => {},
  onSave: () => {},
  ...overrides,
})

describe('CustomRecurrenceModal', () => {
  beforeAll(() => {
    moment.tz.setDefault(defaultTZ)
  })

  it('renders', () => {
    const {getByText, getByTestId} = render(<CustomRecurrenceModal {...defaultProps()} />)

    expect(getByText('Custom Repeating Event')).toBeInTheDocument()
    expect(getByTestId('custom-recurrence')).toBeInTheDocument()
  })

  it('calls onDismiss when the close button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByText} = render(<CustomRecurrenceModal {...defaultProps({onDismiss})} />)

    getByText('Close').click()

    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls onDismiss when the cancel button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByText} = render(<CustomRecurrenceModal {...defaultProps({onDismiss})} />)

    getByText('Cancel').click()

    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls onSave when the Done button is clicked', () => {
    const onSave = jest.fn()
    const {getByText} = render(<CustomRecurrenceModal {...defaultProps({onSave})} />)

    getByText('Done').click()

    expect(onSave).toHaveBeenCalledWith('FREQ=DAILY;INTERVAL=1;COUNT=5')
  })

  it('calls onSave witn an updated RRULE', () => {
    const onSave = jest.fn()
    const {getByText, getByDisplayValue} = render(
      <CustomRecurrenceModal {...defaultProps({onSave})} />
    )

    const interval = getByDisplayValue('1')
    fireEvent.change(interval, {target: {value: '2'}})
    getByText('Done').click()

    expect(onSave).toHaveBeenCalledWith('FREQ=DAILY;INTERVAL=2;COUNT=5')
  })
})
