/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ConfirmActionButtonBar from '../ConfirmActionButtonBar'

describe('ConfirmActionButtonBar', () => {
  it('can render both buttons', () => {
    const {getByText} = render(
      <ConfirmActionButtonBar primaryLabel="primary" secondaryLabel="secondary" />
    )
    expect(getByText('primary')).toBeInTheDocument()
    expect(getByText('secondary')).toBeInTheDocument()
    expect(document.querySelectorAll('button')).toHaveLength(2)
  })

  it('can render just the primary button', () => {
    const {getByText} = render(<ConfirmActionButtonBar primaryLabel="primary" />)
    expect(getByText('primary').closest('button').getAttribute('disabled')).toBe(null)
    expect(document.querySelectorAll('button')).toHaveLength(1)
  })

  it('can render just the secondary button', () => {
    const {getByText} = render(<ConfirmActionButtonBar secondaryLabel="secondary" />)
    expect(getByText('secondary')).toBeInTheDocument()
    expect(document.querySelectorAll('button')).toHaveLength(1)
  })

  it('invokes callbacks', () => {
    const primaryClick = jest.fn()
    const secondaryClick = jest.fn()
    const {getByText} = render(
      <ConfirmActionButtonBar
        primaryLabel="primary"
        secondaryLabel="secondary"
        onPrimaryClick={primaryClick}
        onSecondaryClick={secondaryClick}
      />
    )
    fireEvent.click(getByText('primary'))
    expect(primaryClick).toHaveBeenCalled()
    fireEvent.click(getByText('secondary'))
    expect(secondaryClick).toHaveBeenCalled()
  })

  it('can disable the primary button', () => {
    const {getByText} = render(
      <ConfirmActionButtonBar primaryLabel="primary" primaryDisabled={true} />
    )
    expect(getByText('primary').closest('button').getAttribute('disabled')).toBe('')
  })
})
