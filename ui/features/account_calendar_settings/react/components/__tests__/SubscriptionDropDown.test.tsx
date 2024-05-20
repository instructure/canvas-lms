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
import {render} from '@testing-library/react'
import SubscriptionDropDown, {type ComponentProps} from '../SubscriptionDropDown'

const defaultProps: ComponentProps = {
  accountId: 1,
  autoSubscription: false,
  disabled: false,
  onChange: jest.fn(),
  accountName: 'Test',
}

describe('SubscriptionDropDown', () => {
  it('renders the proper option', () => {
    const {getByTestId, rerender} = render(
      <SubscriptionDropDown {...defaultProps} autoSubscription={true} />
    )
    expect(getByTestId('subscription-dropdown')?.getAttribute('value')).toBe('Auto subscribe')
    rerender(<SubscriptionDropDown {...defaultProps} autoSubscription={false} />)
    expect(getByTestId('subscription-dropdown')?.getAttribute('value')).toBe('Manual subscribe')
  })

  it('disables the dropdown when disabled is passed', () => {
    const {getByTestId} = render(<SubscriptionDropDown {...defaultProps} disabled={true} />)
    expect(getByTestId('subscription-dropdown'))?.toBeDisabled()
  })

  it('calls onChange with the accountId and the new value', () => {
    const onChange = jest.fn()
    const {getByTestId, getByText} = render(
      <SubscriptionDropDown {...defaultProps} onChange={onChange} />
    )
    // display options
    getByTestId('subscription-dropdown').click()
    // select new option
    getByText('Auto subscribe').click()
    expect(onChange).toHaveBeenCalledWith(defaultProps.accountId, true)
  })
})
