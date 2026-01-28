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

import {render, fireEvent} from '@testing-library/react'
import {SecondaryInfoDisplay} from '@canvas/outcomes/react/utils/constants'
import {SecondaryInfoSelector, SecondaryInfoSelectorProps} from '../SecondaryInfoSelector'

describe('SecondaryInfoSelector', () => {
  const defaultProps: SecondaryInfoSelectorProps = {
    value: SecondaryInfoDisplay.NONE,
    onChange: vi.fn(),
  }

  it('renders all option items', () => {
    const {getByText} = render(<SecondaryInfoSelector {...defaultProps} />)
    expect(getByText('SIS ID')).toBeInTheDocument()
    expect(getByText('Integration ID')).toBeInTheDocument()
    expect(getByText('Login ID')).toBeInTheDocument()
    expect(getByText('None')).toBeInTheDocument()
  })

  it('calls onChange when an option is clicked', () => {
    const onChange = vi.fn()
    const {getByLabelText} = render(<SecondaryInfoSelector {...defaultProps} onChange={onChange} />)
    const sisIdInput = getByLabelText('SIS ID')
    fireEvent.click(sisIdInput)
    expect(onChange).toHaveBeenCalledWith(SecondaryInfoDisplay.SIS_ID)
  })
})
