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
import {fireEvent} from 'react-testing-library'
import {ConnectedWhitelist} from '../Whitelist'
import {renderWithRedux} from './utils'

describe('ConnectedWhitelist', () => {
  it('renders items on the whitelist after they are added', () => {
    const {getByLabelText, getByText, container} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Add Domain')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = container.querySelector('button')
    fireEvent.click(button)

    const domainCellEntry = getByText('instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('renders the tools whitelist when present', () => {
    const {getByText} = renderWithRedux(<ConnectedWhitelist context="account" contextId="1" />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com'],
          tools: ['eduappcenter.com']
        }
      }
    })

    const toolDomain = getByText('eduappcenter.com')
    expect(toolDomain).toBeInTheDocument()
  })
  it('shows an error message when an invalid domain is entered', () => {
    const {getByLabelText, getByText, container} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Add Domain')
    fireEvent.input(domainInput, {target: {value: 'fake'}})

    const button = container.querySelector('button')
    fireEvent.click(button)

    const errorMessage = getByText('Invalid domain')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows the correct count for the whitelist', () => {
    const {getByLabelText, getByText, container} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Add Domain')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = container.querySelector('button')
    fireEvent.click(button)

    const countString = getByText('Whitelist (1/100)')
    expect(countString).toBeInTheDocument()
  })

  it('clears the input box after a successful submisssion', () => {
    const {getByLabelText, container} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Add Domain')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = container.querySelector('button')
    fireEvent.click(button)

    expect(domainInput.getAttribute('value')).toBe('')
  })
})
