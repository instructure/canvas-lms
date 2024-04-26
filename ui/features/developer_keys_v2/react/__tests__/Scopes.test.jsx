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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import sinon from 'sinon'
import Scopes from '../Scopes'

const defaultProps = (pending = false, requireScopes = true, onRequireScopesChange = () => {}) => ({
  developerKey: {
    allow_includes: true,
  },
  availableScopes: {
    oauth: [
      {
        resource: 'oauth',
        verb: 'GET',
        scope: '/auth/userinfo',
      },
    ],
    account_domain_lookups: [
      {
        resource: 'account_domain_lookups',
        verb: 'GET',
        path: '/api/v1/accounts/search',
        scope: 'url:GET|/api/v1/accounts/search',
      },
      {
        resource: 'account_domain_lookups',
        verb: 'POST',
        path: '/api/v1/account_domain_lookups',
        scope: 'url:POST|/api/v1/account_domain_lookups',
      },
    ],
  },
  availableScopesPending: pending,
  dispatch: () => {},
  listScopesSet: () => {},
  updateDeveloperKey: () => {},
  listDeveloperKeyScopesSet: () => {},
  requireScopes,
  onRequireScopesChange,
})

const renderScopes = (pending, requireScopes, onRequireScopesChange) => {
  const ref = React.createRef()
  const wrapper = render(
    <Scopes {...defaultProps(pending, requireScopes, onRequireScopesChange)} ref={ref} />
  )

  return {ref, wrapper}
}

describe('Scopes', () => {
  describe('when the "includes" checkbox FF is set in the ENV', () => {
    let wrapper

    beforeEach(() => {
      window.ENV = {
        includesFeatureFlagEnabled: true,
      }

      const {wrapper: innerWrapper} = renderScopes()

      wrapper = innerWrapper
    })

    it('renders the "includes" checkbox', () => {
      expect(
        wrapper.container.querySelector("[data-automation='includes-checkbox']")
      ).toBeInTheDocument()
    })
  })

  it('renders a spinner if scope state is "pending"', () => {
    renderScopes(true)

    expect(screen.getByText('Loading Available Scopes')).toBeInTheDocument()
  })

  it('hiding spinner if scope state is not "pending"', () => {
    renderScopes(false)

    expect(screen.queryByText('Loading Available Scopes')).not.toBeInTheDocument()
  })

  it('defaults the filter state to an empty string', () => {
    const {ref} = renderScopes()

    expect(ref.current.state.filter).toBe('')
  })

  it('handles filter input change by setting the filter state', () => {
    const {ref} = renderScopes()
    const eventDup = {currentTarget: {value: 'banana'}}

    ref.current.handleFilterChange(eventDup)

    expect(ref.current.state.filter).toBe('banana')
  })

  it('renders Billboard if requireScopes is false', () => {
    renderScopes(false, false)

    expect(
      screen.getByRole('heading', {
        name: /when scope enforcement is disabled, tokens have access to all endpoints available to the authorizing user\./i,
      })
    ).toBeInTheDocument()
  })

  it('does not render search box if requireScopes is false', () => {
    renderScopes(false, false)

    expect(screen.queryByRole('textbox')).not.toBeInTheDocument()
  })

  it('does not render Billboard if requireScopes is true', () => {
    renderScopes(false, true)

    expect(
      screen.queryByRole('heading', {
        name: /when scope enforcement is disabled, tokens have access to all endpoints available to the authorizing user\./i,
      })
    ).not.toBeInTheDocument()
  })

  it('renders ScopesList if requireScopes is true', () => {
    const {wrapper} = renderScopes(false, true)

    expect(wrapper.container.querySelector("[data-automation='scopes-list']")).toBeInTheDocument()
  })

  it('does render search box if requireScopes is true', () => {
    renderScopes()

    expect(
      screen.getByRole('searchbox', {
        name: /search endpoints/i,
      })
    ).toBeInTheDocument()
  })

  it('controls requireScopes change when clicking requireScopes button', async () => {
    const requireScopesStub = sinon.stub()

    renderScopes(false, true, requireScopesStub)

    await userEvent.click(screen.getByLabelText(/enforce scopes/i))

    expect(requireScopesStub.called).toBe(true)
  })
})
