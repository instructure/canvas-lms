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
import userEvent from '@testing-library/user-event'
import {
  OutcomeArrangementSelector,
  OutcomeArrangementSelectorProps,
} from '../OutcomeArrangementSelector'
import {OutcomeArrangement} from '@canvas/outcomes/react/utils/constants'

describe('OutcomeArrangementSelector', () => {
  const defaultProps: OutcomeArrangementSelectorProps = {
    value: OutcomeArrangement.UPLOAD_ORDER,
    onChange: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the dropdown with label', () => {
    render(<OutcomeArrangementSelector {...defaultProps} />)
    expect(screen.getByText('Arrange Outcomes by')).toBeInTheDocument()
  })

  it('renders the helper text', () => {
    render(<OutcomeArrangementSelector {...defaultProps} />)
    expect(screen.getByText('(You may drag & drop columns to re-arrange)')).toBeInTheDocument()
  })

  it('displays the selected value', () => {
    render(<OutcomeArrangementSelector {...defaultProps} value={OutcomeArrangement.ALPHABETICAL} />)
    expect(screen.getByDisplayValue('Alphabetical')).toBeInTheDocument()
  })

  it('calls onChange when an option is selected', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<OutcomeArrangementSelector {...defaultProps} onChange={onChange} />)

    const select = screen.getByLabelText('Arrange Outcomes by')
    await user.click(select)

    const alphabeticalOption = await screen.findByText('Alphabetical')
    await user.click(alphabeticalOption)

    expect(onChange).toHaveBeenCalledWith(OutcomeArrangement.ALPHABETICAL)
  })

  it('defaults to UPLOAD_ORDER when value is undefined', () => {
    render(<OutcomeArrangementSelector {...defaultProps} value={undefined} />)
    expect(screen.getByDisplayValue('Upload Order')).toBeInTheDocument()
  })

  it('displays CUSTOM when value is CUSTOM', () => {
    render(<OutcomeArrangementSelector {...defaultProps} value={OutcomeArrangement.CUSTOM} />)
    expect(screen.getByDisplayValue('Custom')).toBeInTheDocument()
  })

  it('displays UPLOAD_ORDER when value is UPLOAD_ORDER', () => {
    render(<OutcomeArrangementSelector {...defaultProps} value={OutcomeArrangement.UPLOAD_ORDER} />)
    expect(screen.getByDisplayValue('Upload Order')).toBeInTheDocument()
  })
})
