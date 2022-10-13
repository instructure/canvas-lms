/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, fireEvent, act} from '@testing-library/react'
import OutcomesPopover from '../OutcomesPopover'

jest.useFakeTimers()

describe('OutcomesPopover', () => {
  let onClearHandlerMock
  const generateOutcomes = num =>
    new Array(num).fill(0).reduce(
      (acc, _curr, idx) => ({
        ...acc,
        [idx + 1]: {
          _id: (idx + 1).toString(),
          linkId: (idx + 1).toString(),
          title: `Outcome ${idx + 1}`,
          canUnlink: false,
        },
      }),
      {}
    )

  const defaultProps = (numberToGenerate = 2) => ({
    outcomes: generateOutcomes(numberToGenerate),
    outcomeCount: numberToGenerate,
    onClearHandler: onClearHandlerMock,
  })

  beforeAll(() => {
    window.ENV.LOCALE = 'en'
    onClearHandlerMock = jest.fn()
  })

  afterEach(() => {
    window.ENV = {}
    jest.clearAllMocks()
  })

  it('renders the OutcomesPopover component', () => {
    const {getByText} = render(<OutcomesPopover {...defaultProps(2)} />)
    expect(getByText('2 Outcomes Selected')).toBeInTheDocument()
    expect(getByText('2 Outcomes Selected').closest('button')).toBeEnabled()
  })

  it('renders the OutcomesPopover component with 0 outcomes selected', () => {
    const {getByText} = render(<OutcomesPopover {...defaultProps(0)} />)
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    expect(getByText('0 Outcomes Selected').closest('button')).toHaveAttribute(
      'aria-disabled',
      'true'
    )
  })

  it('shows details on click', () => {
    const {getByText, getByRole} = render(<OutcomesPopover {...defaultProps(2)} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(getByText('Selected')).toBeInTheDocument()
    expect(button.getAttribute('aria-expanded')).toBe('true')
  })

  it('closes popover when clicking Close button', () => {
    const {getByRole, getByText} = render(<OutcomesPopover {...defaultProps(2)} />)
    const button = getByRole('button')
    fireEvent.click(button)
    const closeButton = getByText('Close')
    fireEvent.click(closeButton)
    expect(button.getAttribute('aria-expanded')).toBe('false')
  })

  it('shows outcomes in alphanumerical order', async () => {
    const props = {
      outcomes: {
        22: {_id: '22', linkId: '22', title: 'Outcome 22', canUnlink: false},
        1: {_id: '1', linkId: '1', title: 'Outcome 1', canUnlink: false},
        2: {_id: '2', linkId: '2', title: 'Outcome 2', canUnlink: false},
        12: {_id: '12', linkId: '12', title: 'Outcome 12', canUnlink: false},
      },
      outcomeCount: 4,
    }
    const {findAllByText, getByRole} = render(
      <OutcomesPopover {...props} onClearHandler={onClearHandlerMock} />
    )
    const button = getByRole('button')
    fireEvent.click(button)
    await act(async () => jest.runOnlyPendingTimers())
    const outcomes = await findAllByText(/Outcome /)
    expect(outcomes[0]).toContainHTML('Outcome 1')
    expect(outcomes[1]).toContainHTML('Outcome 2')
    expect(outcomes[2]).toContainHTML('Outcome 12')
    expect(outcomes[3]).toContainHTML('Outcome 22')
  })

  it('closes popover and calls onClearHandler when user clicks Clear all link', () => {
    const {getByRole, getByText} = render(<OutcomesPopover {...defaultProps(2)} />)
    const button = getByRole('button')
    fireEvent.click(button)
    fireEvent.click(getByText('Clear all'))
    expect(button.getAttribute('aria-expanded')).toBe('false')
    expect(onClearHandlerMock).toHaveBeenCalled()
  })
})
