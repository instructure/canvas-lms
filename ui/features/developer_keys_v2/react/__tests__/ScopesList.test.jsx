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
import {render, screen, fireEvent} from '@testing-library/react'
import DeveloperKeyScopesList from '../ScopesList'

// Mock LazyLoad to render children immediately in tests
jest.mock('react-lazy-load', () => ({
  __esModule: true,
  default: ({children}) => <div className="LazyLoad">{children}</div>,
}))

const scopes = {
  oauth: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth1: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oaut2: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth3: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth4: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth5: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth6: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth7: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth8: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth9: [
    {
      resource: 'oauth',
      verb: 'GET',
      scope: '/auth/userinfo',
    },
  ],
  oauth10: [
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
}

const baseProps = {
  dispatch: () => {},
  listDeveloperKeyScopesSet: () => {},
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
  filter: '',
  actions: {listDeveloperKeyScopesSet: () => {}},
}

const defaultProps = props => ({
  ...baseProps,
  ...props,
})

const renderDeveloperKeyScopesList = props => {
  const ref = React.createRef()
  const wrapper = render(<DeveloperKeyScopesList {...defaultProps(props)} ref={ref} />)

  return {ref, wrapper}
}

describe('DeveloperKeyScopesList', () => {
  it('renders each group', () => {
    renderDeveloperKeyScopesList()

    expect(screen.getByText('oauth')).toBeInTheDocument()
    expect(screen.getByText('account_domain_lookups')).toBeInTheDocument()
  })

  it('uses the correct handler the checkbox is checked', () => {
    const {ref} = renderDeveloperKeyScopesList()
    const stubbedHandler = jest.fn()
    const component = ref.current
    const checkBox = screen.getByLabelText(/Enable all read only scopes/i)

    component.handleReadOnlySelected = stubbedHandler
    component.forceUpdate()

    fireEvent.click(checkBox)

    expect(stubbedHandler).toHaveBeenCalled()
  })

  it('only renders groups with names that match the filter', () => {
    renderDeveloperKeyScopesList({filter: 'Account'})

    expect(screen.getByText('account_domain_lookups')).toBeInTheDocument()
    expect(screen.queryByText('oauth')).not.toBeInTheDocument()
  })

  describe('filtering', () => {
    const scopesWithMultipleInGroup = {
      ...baseProps.availableScopes,
      assignments: [
        {
          resource: 'assignments',
          verb: 'GET',
          path: '/api/v1/courses/:course_id/assignments',
          scope: 'url:GET|/api/v1/courses/:course_id/assignments',
        },
        {
          resource: 'assignments',
          verb: 'POST',
          path: '/api/v1/courses/:course_id/assignments',
          scope: 'url:POST|/api/v1/courses/:course_id/assignments',
        },
        {
          resource: 'assignments',
          verb: 'DELETE',
          path: '/api/v1/courses/:course_id/assignments/:id',
          scope: 'url:DELETE|/api/v1/courses/:course_id/assignments/:id',
        },
      ],
    }

    it('filters groups by name (case insensitive)', () => {
      renderDeveloperKeyScopesList({
        availableScopes: scopesWithMultipleInGroup,
        filter: 'assign',
      })

      expect(screen.getByText('assignments')).toBeInTheDocument()
      expect(screen.queryByText('oauth')).not.toBeInTheDocument()
      expect(screen.queryByText('account_domain_lookups')).not.toBeInTheDocument()
    })

    it('filters individual scopes within groups', () => {
      renderDeveloperKeyScopesList({
        availableScopes: scopesWithMultipleInGroup,
        filter: 'DELETE',
      })

      expect(screen.getByText('assignments')).toBeInTheDocument()
      expect(screen.queryByText('oauth')).not.toBeInTheDocument()
      expect(screen.queryByText('account_domain_lookups')).not.toBeInTheDocument()
    })

    it('shows only filtered scopes when group name does not match', () => {
      const {wrapper} = renderDeveloperKeyScopesList({
        availableScopes: scopesWithMultipleInGroup,
        filter: 'DELETE',
      })

      expect(screen.getByText('assignments')).toBeInTheDocument()

      const scopeElements = wrapper.container.querySelectorAll(
        '[data-automation="developer-key-scope"]',
      )
      expect(scopeElements).toHaveLength(1)
      expect(scopeElements[0].textContent).toContain('DELETE')
      expect(scopeElements[0].textContent).toContain(
        'url:DELETE|/api/v1/courses/:course_id/assignments/:id',
      )
    })

    it('shows all scopes in a group when group name matches filter', () => {
      const {wrapper} = renderDeveloperKeyScopesList({
        availableScopes: scopesWithMultipleInGroup,
        filter: 'assignments',
      })

      expect(screen.getByText('assignments')).toBeInTheDocument()
      expect(screen.queryByText('oauth')).not.toBeInTheDocument()
      expect(screen.queryByText('account_domain_lookups')).not.toBeInTheDocument()

      expect(screen.getByLabelText(/All assignments scopes/i)).toBeInTheDocument()
    })

    it('hides groups that do not match filter at all', () => {
      renderDeveloperKeyScopesList({
        availableScopes: scopesWithMultipleInGroup,
        filter: 'nonexistent',
      })

      expect(screen.queryByText('oauth')).not.toBeInTheDocument()
      expect(screen.queryByText('account_domain_lookups')).not.toBeInTheDocument()
      expect(screen.queryByText('assignments')).not.toBeInTheDocument()
    })

    it('shows all groups when filter is empty', () => {
      renderDeveloperKeyScopesList({
        availableScopes: scopesWithMultipleInGroup,
        filter: '',
      })

      expect(screen.getByText('oauth')).toBeInTheDocument()
      expect(screen.getByText('account_domain_lookups')).toBeInTheDocument()
      expect(screen.getByText('assignments')).toBeInTheDocument()
    })

    it('performs case-insensitive filtering', () => {
      const {unmount: unmount1} = render(
        <DeveloperKeyScopesList {...defaultProps({filter: 'OAUTH'})} />,
      )
      expect(screen.getByText('oauth')).toBeInTheDocument()
      unmount1()

      const {unmount: unmount2} = render(
        <DeveloperKeyScopesList {...defaultProps({filter: 'oauth'})} />,
      )
      expect(screen.getByText('oauth')).toBeInTheDocument()
      unmount2()

      render(<DeveloperKeyScopesList {...defaultProps({filter: 'OaUtH'})} />)
      expect(screen.getByText('oauth')).toBeInTheDocument()
    })
  })

  it('only renders 8 groups on the initial render', () => {
    const {ref} = renderDeveloperKeyScopesList({availableScopes: scopes})

    expect(ref.current.state.availableScopes).toHaveLength(8)
  })

  describe('handleReadOnlySelected', () => {
    it('selects all scopes with GET as the verb', () => {
      const {ref} = renderDeveloperKeyScopesList()
      const fakeEvent = {
        currentTarget: {
          checked: true,
        },
      }

      ref.current.handleReadOnlySelected(fakeEvent)

      expect(ref.current.state.selectedScopes).toEqual(
        expect.arrayContaining(['/auth/userinfo', 'url:GET|/api/v1/accounts/search']),
      )
    })

    it('deselects all scopes with GET as the verb', () => {
      const {ref} = renderDeveloperKeyScopesList()
      const fakeSelectEvent = {
        currentTarget: {
          checked: true,
        },
      }
      const fakeDeselectEvent = {
        currentTarget: {
          checked: false,
        },
      }

      ref.current.handleReadOnlySelected(fakeSelectEvent)
      ref.current.handleReadOnlySelected(fakeDeselectEvent)

      expect(ref.current.state.selectedScopes).toEqual(expect.arrayContaining([]))
    })
  })

  describe('initial state', () => {
    it('initializes selectedScopes to empty array if selectedScopes prop is undefined', () => {
      const {ref} = renderDeveloperKeyScopesList()

      expect(ref.current.state.selectedScopes).toEqual([])
    })
  })

  describe('verify no duplicate elements get posted', () => {
    it('filter out duplicate elements when setting the state', () => {
      const {ref} = renderDeveloperKeyScopesList()
      const duplicate = ['a', 'b', 'c', 'd', 'a', 'a', 'a', 'b']

      ref.current.setSelectedScopes(duplicate)

      expect(ref.current.state.selectedScopes).toEqual(expect.arrayContaining(['a', 'b', 'c', 'd']))
    })

    it('does nothing to empty array when setting the state', () => {
      const {ref} = renderDeveloperKeyScopesList()

      ref.current.setSelectedScopes([])

      expect(ref.current.state.selectedScopes).toEqual([])
    })

    it('does nothing to array with no duplicate elements when setting the state', () => {
      const {ref} = renderDeveloperKeyScopesList()
      const noDuplicate = ['a', 'b', 'c', 'd', 'e', 'f', 'g']

      ref.current.setSelectedScopes(noDuplicate)

      expect(ref.current.state.selectedScopes).toEqual(['a', 'b', 'c', 'd', 'e', 'f', 'g'])
    })
  })

  describe('setSelectedScopes', () => {
    describe('Read Only check box', () => {
      it('is not checked when no scope is selected', () => {
        const {ref} = renderDeveloperKeyScopesList()

        ref.current.setSelectedScopes([])

        expect(ref.current.state.readOnlySelected).toBeFalsy()
      })

      it('is checked when all possible GET is selected', () => {
        const {ref} = renderDeveloperKeyScopesList()

        ref.current.setSelectedScopes(['/auth/userinfo', 'url:GET|/api/v1/accounts/search'])

        expect(ref.current.state.readOnlySelected).toBeTruthy()
      })

      it('is not checked when some of the GET is selected but nothing else', () => {
        const {ref} = renderDeveloperKeyScopesList()

        ref.current.setSelectedScopes(['/auth/userinfo'])

        expect(ref.current.state.readOnlySelected).toEqual(false)
      })

      it('is not checked when any verb that is not GET and all possible GET is selected', () => {
        const {ref} = renderDeveloperKeyScopesList()

        ref.current.setSelectedScopes([
          'url:POST|/api/v1/account_domain_lookups',
          '/auth/userinfo',
          'url:GET|/api/v1/accounts/search',
        ])

        expect(ref.current.state.readOnlySelected).toEqual(false)
      })

      it('is not checked when any verb that is not GET is selected only', () => {
        const {ref} = renderDeveloperKeyScopesList()

        ref.current.setSelectedScopes(['url:POST|/api/v1/account_domain_lookups'])

        expect(ref.current.state.readOnlySelected).toEqual(false)
      })
    })
  })
})
