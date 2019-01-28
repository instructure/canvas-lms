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
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const domainCellEntry = getByText('instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('handles adding wildcard entries to the whitelist', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: '*.instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const domainCellEntry = getByText('*.instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('renders the tools whitelist when present', () => {
    const {getByText} = renderWithRedux(<ConnectedWhitelist context="account" contextId="1" />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com'],
          tools: {
            'eduappcenter.com': [
              {
                id: '1',
                name: 'Cool Tool 1',
                account_id: '1'
              }
            ]
          }
        }
      }
    })

    const toolDomain = getByText('eduappcenter.com')
    expect(toolDomain).toBeInTheDocument()
  })
  it('shows an error message when an invalid domain is entered', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'fake'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const errorMessage = getByText('Invalid domain')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows the correct count for the whitelist', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const countString = getByText('Whitelist (1/50)')
    expect(countString).toBeInTheDocument()
  })

  it('clears the input box after a successful submisssion', () => {
    const {getByLabelText} = renderWithRedux(<ConnectedWhitelist context="account" contextId="1" />)

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    expect(domainInput.getAttribute('value')).toBe('')
  })

  it('removes items when clicking the delete icon', () => {
    const {getByText, queryByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />,
      {
        initialState: {
          whitelistedDomains: {
            account: ['instructure.com', 'canvaslms.com']
          }
        }
      }
    )

    const TEXT = 'Remove instructure.com from the whitelist'

    const button = getByText(TEXT)
    fireEvent.click(button)
    expect(queryByText(TEXT)).toBeNull()
  })

  it('sets focus to the previous whitelist item delete icon when deleting', () => {
    const {getByText, getByTestId} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />,
      {
        initialState: {
          whitelistedDomains: {
            account: ['instructure.com', 'canvaslms.com']
          }
        }
      }
    )

    const button = getByText('Remove canvaslms.com from the whitelist')
    fireEvent.click(button)
    const previousButton = getByTestId('delete-button-instructure.com')

    expect(previousButton).toHaveFocus()
  })

  it('sets focus to the the add domain button when removing the first positioned domain from the whitelist', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />,
      {
        initialState: {
          whitelistedDomains: {
            account: ['instructure.com', 'canvaslms.com']
          }
        }
      }
    )

    const deleteButton = getByText('Remove instructure.com from the whitelist')
    fireEvent.click(deleteButton)
    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toHaveFocus()
  })

  it('sets focus to the add domain button when removing the last remaining domain from the whitelist', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />,
      {
        initialState: {
          whitelistedDomains: {
            account: ['instructure.com']
          }
        }
      }
    )

    const deleteButton = getByText('Remove instructure.com from the whitelist')
    fireEvent.click(deleteButton)

    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toHaveFocus()
  })

  it('disables adding additional domains when there are 50 already present', () => {
    const exampleDomains = []
    for (let i = 0; i < 50; i++) {
      exampleDomains.push(`domain-${i}.com`)
    }
    const {getByLabelText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" />,
      {
        initialState: {
          whitelistedDomains: {
            account: exampleDomains
          }
        }
      }
    )

    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toBeDisabled()
  })

  it('shows a message indicating whitelist has been reached', () => {
    const exampleDomains = []
    for (let i = 0; i < 50; i++) {
      exampleDomains.push(`domain-${i}.com`)
    }
    const {getByText} = renderWithRedux(<ConnectedWhitelist context="account" contextId="1" />, {
      initialState: {
        whitelistedDomains: {
          account: exampleDomains
        }
      }
    })

    const domainMessage = getByText(/You have reached the domain limit/)
    expect(domainMessage).toBeInTheDocument()
  })
})
