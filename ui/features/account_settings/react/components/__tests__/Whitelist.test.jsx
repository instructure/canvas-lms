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
import {render, fireEvent} from '@testing-library/react'
import {Whitelist} from '../Whitelist'

const defaultWhitelistedDomains = {
  account: [],
  effective: [],
  inherited: [],
  tools: {},
}

const defaultProps = {
  maxDomains: 50,
  whitelistedDomains: defaultWhitelistedDomains,
  onAddDomain: vi.fn(),
  onRemoveDomain: vi.fn(),
}

function renderWhitelist(overrides = {}) {
  const props = {...defaultProps, ...overrides}
  if (overrides.onAddDomain === undefined) {
    props.onAddDomain = vi.fn()
  }
  if (overrides.onRemoveDomain === undefined) {
    props.onRemoveDomain = vi.fn()
  }
  return render(<Whitelist {...props} />)
}

describe('Whitelist', () => {
  beforeEach(() => {
    window.ENV = {ACCOUNT: {id: '1234'}}
  })

  it('renders items on the allowed domain list after they are added', () => {
    const onAddDomain = vi.fn()
    const {getByLabelText, getByText, rerender} = renderWhitelist({onAddDomain})

    const domainInput = getByLabelText('Domain Name *')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    expect(onAddDomain).toHaveBeenCalledWith('instructure.com')

    // Re-render with the domain added (simulating parent state update)
    rerender(
      <Whitelist
        {...defaultProps}
        onAddDomain={onAddDomain}
        whitelistedDomains={{...defaultWhitelistedDomains, account: ['instructure.com']}}
      />,
    )

    const domainCellEntry = getByText('instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('handles adding wildcard entries to the allowed domain list', () => {
    const onAddDomain = vi.fn()
    const {getByLabelText, getByText, rerender} = renderWhitelist({onAddDomain})

    const domainInput = getByLabelText('Domain Name *')
    fireEvent.input(domainInput, {target: {value: '*.instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    expect(onAddDomain).toHaveBeenCalledWith('*.instructure.com')

    rerender(
      <Whitelist
        {...defaultProps}
        onAddDomain={onAddDomain}
        whitelistedDomains={{...defaultWhitelistedDomains, account: ['*.instructure.com']}}
      />,
    )

    const domainCellEntry = getByText('*.instructure.com')
    expect(domainCellEntry).toBeInTheDocument()
  })

  it('renders the empty state when there are no domains', () => {
    const {getByText} = renderWhitelist()
    const emptyState = getByText('No allowed domains')
    expect(emptyState).toBeInTheDocument()
  })

  it('renders the tools domain list when present', () => {
    const {getByText} = renderWhitelist({
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: ['instructure.com'],
        tools: {
          'eduappcenter.com': [{id: '1', name: 'Cool Tool 1', account_id: '1'}],
        },
      },
    })

    const toolDomain = getByText('eduappcenter.com')
    expect(toolDomain).toBeInTheDocument()
  })

  it('shows an error message when an invalid domain is entered', () => {
    const {getByLabelText, getByText} = renderWhitelist()

    const domainInput = getByLabelText('Domain Name *')
    fireEvent.input(domainInput, {target: {value: 'fake'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    const errorMessage = getByText('Invalid domain')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows the correct count for the domain list', () => {
    const {getByText} = renderWhitelist({
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: ['instructure.com'],
      },
    })

    const countString = getByText('Domains (1/50)')
    expect(countString).toBeInTheDocument()
  })

  it('clears the input box after a successful submisssion', () => {
    const {getByLabelText} = renderWhitelist()

    const domainInput = getByLabelText('Domain Name *')
    fireEvent.input(domainInput, {target: {value: 'instructure.com'}})

    const button = getByLabelText('Add Domain')
    fireEvent.click(button)

    expect(domainInput.getAttribute('value')).toBe('')
  })

  it('removes items when clicking the delete icon', () => {
    const onRemoveDomain = vi.fn()
    const {getByText} = renderWhitelist({
      onRemoveDomain,
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: ['instructure.com', 'canvaslms.com'],
      },
    })

    const TEXT = 'Remove instructure.com as an allowed domain'
    const button = getByText(TEXT)
    fireEvent.click(button)
    expect(onRemoveDomain).toHaveBeenCalledWith('instructure.com')
  })

  it('sets focus to the previous domain delete icon when deleting', () => {
    const onRemoveDomain = vi.fn()
    const {getByText, getByTestId} = renderWhitelist({
      onRemoveDomain,
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: ['instructure.com', 'canvaslms.com'],
      },
    })

    const button = getByText('Remove canvaslms.com as an allowed domain')
    fireEvent.click(button)
    const previousButton = getByTestId('delete-button-instructure.com')

    expect(previousButton).toHaveFocus()
  })

  it('sets focus to the the add domain button when removing the first positioned domain from the allowed domain list', () => {
    const onRemoveDomain = vi.fn()
    const {getByLabelText, getByText} = renderWhitelist({
      onRemoveDomain,
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: ['instructure.com', 'canvaslms.com'],
      },
    })

    const deleteButton = getByText('Remove instructure.com as an allowed domain')
    fireEvent.click(deleteButton)
    const addDomainButton = getByLabelText('Add Domain')
    expect(addDomainButton).toHaveFocus()
  })

  it('sets focus to the add domain button when removing the last remaining domain from the allowed domain list', () => {
    const onRemoveDomain = vi.fn()
    const {getByLabelText, getByText} = renderWhitelist({
      onRemoveDomain,
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: ['instructure.com'],
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
    const {getByLabelText} = renderWhitelist({
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: exampleDomains,
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
    const {getByText} = renderWhitelist({
      whitelistedDomains: {
        ...defaultWhitelistedDomains,
        account: exampleDomains,
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
      const {queryByText} = renderWhitelist({
        inherited: true,
        whitelistedDomains: {
          ...defaultWhitelistedDomains,
          account: [],
          inherited: exampleDomains,
        },
      })

      const domainMessage = queryByText(/You have reached the domain limit/)
      expect(domainMessage).toBeNull()
    })

    it('shows an information message indicating that switching to custom will allow changes', () => {
      const {getByText} = renderWhitelist({
        inherited: true,
        isSubAccount: true,
        whitelistedDomains: {
          ...defaultWhitelistedDomains,
          account: [],
          inherited: ['instructure.com', 'canvaslms.com'],
        },
      })

      const message = getByText(
        /Domain editing is disabled when security settings are inherited from a parent account/,
      )
      expect(message).toBeInTheDocument()
    })

    it('shows the allowed domain list from the inherited account', () => {
      const {getByText, queryByText} = renderWhitelist({
        inherited: true,
        whitelistedDomains: {
          ...defaultWhitelistedDomains,
          account: ['canvaslms.com'],
          inherited: ['instructure.com'],
        },
      })

      const badDomain = queryByText('canvaslms.com')
      expect(badDomain).toBeNull()

      const goodDomain = getByText('instructure.com')
      expect(goodDomain).toBeInTheDocument()
    })

    it('does not show the count for the allowed domain list', () => {
      const {queryByText, getByText} = renderWhitelist({
        inherited: true,
      })

      const wrongString = queryByText('Domains (0/50)')
      expect(wrongString).toBeNull()

      const rightString = getByText('Domains')
      expect(rightString).toBeInTheDocument()
    })

    it('does not allow adding items to the list', () => {
      const {getByLabelText} = renderWhitelist({
        inherited: true,
        isSubAccount: true,
        whitelistedDomains: {
          ...defaultWhitelistedDomains,
          inherited: ['instructure.com'],
          account: [],
        },
      })

      const button = getByLabelText('Add Domain')
      expect(button).toBeDisabled()
    })

    it('does not allow removing items from the list', () => {
      const {getByRole} = renderWhitelist({
        inherited: true,
        isSubAccount: true,
        whitelistedDomains: {
          ...defaultWhitelistedDomains,
          inherited: ['instructure.com'],
          account: [],
        },
      })

      const button = getByRole('button', {name: 'Remove instructure.com as an allowed domain'})
      expect(button).toBeDisabled()
    })
  })
})
