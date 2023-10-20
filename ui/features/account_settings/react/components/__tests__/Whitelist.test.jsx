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

const defaultProps = {
  context: 'account',
  accountId: '1',
  contextId: '1',
  maxDomains: 50,
  liveRegion: [],
}

describe('ConnectedWhitelist', () => {
  beforeEach(() => {
    window.ENV = {
      ACCOUNT: {id: '1234'},
    }
  })

  it('renders items on the allowed domain list after they are added', () => {
    const {getByLabelText, getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />)

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const domainCellEntry = getByText('instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('handles adding wildcard entries to the allowed domain list', () => {
    const {getByLabelText, getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />)

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: '*.instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const domainCellEntry = getByText('*.instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('renders the empty state when there are no domains', () => {
    const {getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />)
    const emptyState = getByText('No allowed domains')
    expect(emptyState).toBeInTheDocument()
  })

  it('renders the tools domain list when present', () => {
    const {getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com'],
          tools: {
            'eduappcenter.com': [
              {
                id: '1',
                name: 'Cool Tool 1',
                account_id: '1',
              },
            ],
          },
        },
      },
    })

    const toolDomain = getByText('eduappcenter.com')
    expect(toolDomain).toBeInTheDocument()
  })

  it('shows an error message when an invalid domain is entered', () => {
    const {getByLabelText, getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />)

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'fake'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const errorMessage = getByText('Invalid domain')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows the correct count for the domain list', () => {
    const {getByLabelText, getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />)

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const countString = getByText('Domains (1/50)')
    expect(countString).toBeInTheDocument()
  })

  it('clears the input box after a successful submisssion', () => {
    const {getByLabelText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />)

    const domainInput = getByLabelText('Domain Name')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    expect(domainInput.getAttribute('value')).toBe('')
  })

  it('removes items when clicking the delete icon', () => {
    const {getByText, queryByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com', 'canvaslms.com'],
        },
      },
    })

    const TEXT = 'Remove instructure.com as an allowed domain'

    const button = getByText(TEXT)
    fireEvent.click(button)
    expect(queryByText(TEXT)).toBeNull()
  })

  it('sets focus to the previous domain delete icon when deleting', () => {
    const {getByText, getByTestId} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com', 'canvaslms.com'],
        },
      },
    })

    const button = getByText('Remove canvaslms.com as an allowed domain')
    fireEvent.click(button)
    const previousButton = getByTestId('delete-button-instructure.com')

    expect(previousButton).toHaveFocus()
  })

  it('sets focus to the the add domain button when removing the first positioned domain from the allowed domain list', () => {
    const {getByLabelText, getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com', 'canvaslms.com'],
        },
      },
    })

    const deleteButton = getByText('Remove instructure.com as an allowed domain')
    fireEvent.click(deleteButton)
    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toHaveFocus()
  })

  it('sets focus to the add domain button when removing the last remaining domain from the allowed domain list', () => {
    const {getByLabelText, getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: ['instructure.com'],
        },
      },
    })

    const deleteButton = getByText('Remove instructure.com as an allowed domain')
    fireEvent.click(deleteButton)

    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toHaveFocus()
  })

  it('disables adding additional domains when there are 50 already present', () => {
    const exampleDomains = []
    for (let i = 0; i < 50; i++) {
      exampleDomains.push(`domain-${i}.com`)
    }
    const {getByLabelText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: exampleDomains,
        },
      },
    })

    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toBeDisabled()
  })

  it('shows a message indicating domain limit has been reached', () => {
    const exampleDomains = []
    for (let i = 0; i < 50; i++) {
      exampleDomains.push(`domain-${i}.com`)
    }
    const {getByText} = renderWithRedux(<ConnectedWhitelist {...defaultProps} />, {
      initialState: {
        whitelistedDomains: {
          account: exampleDomains,
        },
      },
    })

    const domainMessage = getByText(/You have reached the domain limit/)
    expect(domainMessage).toBeInTheDocument()
  })

  describe('inherited prop', () => {
    it('does not show a domain limit message', () => {
      const exampleDomains = []
      for (let i = 0; i < 50; i++) {
        exampleDomains.push(`domain-${i}.com`)
      }
      const {queryByText} = renderWithRedux(
        <ConnectedWhitelist {...defaultProps} inherited={true} />,
        {
          initialState: {
            whitelistedDomains: {
              account: [],
              inherited: exampleDomains,
            },
          },
        }
      )

      const domainMessage = queryByText(/You have reached the domain limit/)
      expect(domainMessage).toBeNull()
    })

    it('shows an information message indicating that switching to custom will allow changes', () => {
      const {getByText} = renderWithRedux(
        <ConnectedWhitelist {...defaultProps} inherited={true} isSubAccount={true} />,
        {
          initialState: {
            whitelistedDomains: {
              account: [],
              inherited: ['instructure.com', 'canvaslms.com'],
            },
          },
        }
      )

      const message = getByText(
        /Domain editing is disabled when security settings are inherited from a parent account/
      )
      expect(message).toBeInTheDocument()
    })

    it('shows the allowed domain list from the inherited account', () => {
      const {getByText, queryByText} = renderWithRedux(
        <ConnectedWhitelist {...defaultProps} inherited={true} />,
        {
          initialState: {
            whitelistedDomains: {
              account: ['canvaslms.com'],
              inherited: ['instructure.com'],
            },
          },
        }
      )

      const badDomain = queryByText('canvaslms.com')
      expect(badDomain).toBeNull()

      const goodDomain = getByText('instructure.com')
      expect(goodDomain).toBeInTheDocument()
    })

    it('does not show the count for the allowed domain list', () => {
      const {queryByText, getByText} = renderWithRedux(
        <ConnectedWhitelist {...defaultProps} inherited={true} />
      )

      const wrongString = queryByText('Domains (0/50)')
      expect(wrongString).toBeNull()

      const rightString = getByText('Domains')
      expect(rightString).toBeInTheDocument()
    })

    it('does not allow adding items to the list', () => {
      const {getByLabelText} = renderWithRedux(
        <ConnectedWhitelist {...defaultProps} inherited={true} isSubAccount={true} />,
        {
          initialState: {
            whitelistedDomains: {
              inherited: ['instructure.com'],
              account: [],
            },
          },
        }
      )

      const button = getByLabelText('Add Domain')
      expect(button).toBeDisabled()
    })

    it('does not allow removing items from the list', () => {
      const {getByRole} = renderWithRedux(
        <ConnectedWhitelist {...defaultProps} inherited={true} isSubAccount={true} />,
        {
          initialState: {
            whitelistedDomains: {
              inherited: ['instructure.com'],
              account: [],
            },
          },
        }
      )

      const button = getByRole('button', {name: 'Remove instructure.com as an allowed domain'})
      expect(button).toBeDisabled()
    })
  })
})
