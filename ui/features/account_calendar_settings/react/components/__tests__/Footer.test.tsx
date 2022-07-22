/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render} from '@testing-library/react'

import {Footer} from '../Footer'

const defaultProps = {
  selectedCalendarCount: 3,
  onApplyClicked: jest.fn(),
  enableSaveButton: true
}

describe('Footer', () => {
  it('calls onApplyClicked when apply button is pressed', () => {
    const onApplyClicked = jest.fn()
    const {getByRole} = render(<Footer {...defaultProps} onApplyClicked={onApplyClicked} />)
    getByRole('button', {name: 'Apply Changes'}).click()
    expect(onApplyClicked).toHaveBeenCalledTimes(1)
  })

  it('disables and enables save button according to enableSaveButton prop', () => {
    const {getByRole, rerender} = render(<Footer {...defaultProps} />)
    const button = getByRole('button', {name: 'Apply Changes'})
    expect(button).toBeEnabled()
    rerender(<Footer {...defaultProps} enableSaveButton={false} />)
    expect(button).toBeDisabled()
  })

  it('displays the number of calendars selected', () => {
    const {getByText} = render(<Footer {...defaultProps} />)
    expect(getByText('3 Account Calendars selected')).toBeInTheDocument()
  })
})
