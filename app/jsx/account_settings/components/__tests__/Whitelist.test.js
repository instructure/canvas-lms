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
import {fireEvent} from '@testing-library/react'
import {ConnectedWhitelist} from '../Whitelist'
import {renderWithRedux} from './utils'

describe('ConnectedWhitelist', () => {
  beforeEach(() => {
    window.ENV = {
      ACCOUNT: {id: '1234'}
    }
  })

  it('renders items on the whitelist after they are added', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />
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
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: '*.instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const domainCellEntry = getByText('*.instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('renders the empty state when there are no domains', () => {
    const {getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />
    )
    const emptyState = getByText('No domains whitelisted')
    expect(emptyState).toBeInTheDocument()
  })

  it('renders the tools whitelist when present', () => {
    const {getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
      {
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
      }
    )

    const toolDomain = getByText('eduappcenter.com')
    expect(toolDomain).toBeInTheDocument()
  })

  it('shows an error message when an invalid domain is entered', () => {
    const {getByLabelText, getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />
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
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const countString = getByText('Whitelist (1/50)')
    expect(countString).toBeInTheDocument()
  })

  it('clears the input box after a successful submisssion', () => {
    const {getByLabelText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />
    )

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    expect(domainInput.getAttribute('value')).toBe('')
  })

  it('removes items when clicking the delete icon', () => {
    const {getByText, queryByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
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
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
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
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
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
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
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
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
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

  it('shows a message indicating whitelist limit has been reached', () => {
    const exampleDomains = []
    for (let i = 0; i < 50; i++) {
      exampleDomains.push(`domain-${i}.com`)
    }
    const {getByText} = renderWithRedux(
      <ConnectedWhitelist context="account" contextId="1" maxDomains={50} />,
      {
        initialState: {
          whitelistedDomains: {
            account: exampleDomains
          }
        }
      }
    )

    const domainMessage = getByText(/You have reached the domain limit/)
    expect(domainMessage).toBeInTheDocument()
  })

  describe('inherited prop', () => {
    it('does not show a whitelist limit message', () => {
      const exampleDomains = []
      for (let i = 0; i < 50; i++) {
        exampleDomains.push(`domain-${i}.com`)
      }
      const {queryByText} = renderWithRedux(
        <ConnectedWhitelist context="account" contextId="1" maxDomains={50} inherited />,
        {
          initialState: {
            whitelistedDomains: {
              account: [],
              inherited: exampleDomains
            }
          }
        }
      )

      const domainMessage = queryByText(/You have reached the domain limit/)
      expect(domainMessage).toBeNull()
    })

    it('shows an information message indicating that switching to custom will allow changes', () => {
      const {getByText} = renderWithRedux(
        <ConnectedWhitelist
          context="account"
          contextId="1"
          maxDomains={50}
          inherited
          isSubAccount
        />,
        {
          initialState: {
            whitelistedDomains: {
              account: [],
              inherited: ['instructure.com', 'canvaslms.com']
            }
          }
        }
      )

      const message = getByText(
        /Whitelist editing is disabled when security settings are inherited from a parent account/
      )
      expect(message).toBeInTheDocument()
    })

    it('shows the whitelist from the inherited account', () => {
      const {getByText, queryByText} = renderWithRedux(
        <ConnectedWhitelist context="account" contextId="1" maxDomains={50} inherited />,
        {
          initialState: {
            whitelistedDomains: {
              account: ['canvaslms.com'],
              inherited: ['instructure.com']
            }
          }
        }
      )

      const badDomain = queryByText('canvaslms.com')
      expect(badDomain).toBeNull()

      const goodDomain = getByText('instructure.com')
      expect(goodDomain).toBeInTheDocument()
    })

    it('does not show the count for the whitelist', () => {
      const {queryByText, getByText} = renderWithRedux(
        <ConnectedWhitelist context="account" contextId="1" maxDomains={50} inherited />
      )

      const wrongString = queryByText('Whitelist (0/50)')
      expect(wrongString).toBeNull()

      const rightString = getByText('Whitelist')
      expect(rightString).toBeInTheDocument()
    })

    it('does not allow adding items to the list', () => {
      const {getByLabelText} = renderWithRedux(
        <ConnectedWhitelist
          context="account"
          contextId="1"
          maxDomains={50}
          inherited
          isSubAccount
        />,
        {
          initialState: {
            whitelistedDomains: {
              inherited: ['instructure.com'],
              account: []
            }
          }
        }
      )

      const button = getByLabelText('Add Domain')
      expect(button).toBeDisabled()
    })

    it('does not allow removing items from the list', () => {
      const {getByText} = renderWithRedux(
        <ConnectedWhitelist
          context="account"
          contextId="1"
          maxDomains={50}
          inherited
          isSubAccount
        />,
        {
          initialState: {
            whitelistedDomains: {
              inherited: ['instructure.com'],
              account: []
            }
          }
        }
      )

      const button = getByText('Remove instructure.com from the whitelist')
      expect(button).toBeDisabled()
    })
  })

  describe('isSubAccount', () => {
    it('does not show the option to view a violation log', () => {
      const {queryByText} = renderWithRedux(
        <ConnectedWhitelist context="account" contextId="1" maxDomains={50} isSubAccount />
      )
      const violationLogBtn = queryByText('View Violation Log')
      expect(violationLogBtn).toBeNull()
    })
  })
})
