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
import ScopesGroup from '../ScopesGroup'

const scopes = [
  {
    resource: 'account_domain_lookups',
    verb: 'GET',
    path: '/api/v1/accounts/search',
    scope: 'url:GET|/api/v1/accounts/search',
  },
  {
    resource: 'account_domain_lookups',
    verb: 'POST',
    path: '/api/v1/accounts/search',
    scope: 'url:POST|/api/v1/accounts/search',
  },
]

const baseProps = {
  setSelectedScopes: jest.fn(),
  setReadOnlySelected: jest.fn(),
  selectedScopes: [scopes[0].scope],
  scopes,
  name: 'Cool Scope Group',
}

const defaultProps = props => ({
  ...baseProps,
  ...props,
})

const renderScopesGroup = props => render(<ScopesGroup {...defaultProps(props)} />)

describe('ScopesGroup', () => {
  it("adds all scopes to 'selected scopes' when the checkbox is checked", () => {
    renderScopesGroup()

    fireEvent.click(screen.getByRole('checkbox'))

    expect(baseProps.setSelectedScopes).toHaveBeenCalled()
  })

  it("removes all scopes from 'selected scopes' when the checbox is unchecked", () => {
    renderScopesGroup()

    fireEvent.click(screen.getByRole('checkbox'))

    expect(baseProps.setSelectedScopes).toHaveBeenCalledTimes(2)
  })

  it('checks the selected scopes', () => {
    renderScopesGroup()

    fireEvent.click(screen.getByRole('button'))

    expect(screen.getAllByRole('checkbox')[1]).toBeChecked()
  })

  it('renders the http verb for each selected scope', () => {
    renderScopesGroup()

    fireEvent.click(screen.getByRole('button'))

    expect(screen.getByRole('button', {text: baseProps.scopes[0].verb})).toBeInTheDocument()
    expect(screen.getByRole('button', {text: baseProps.scopes[1].verb})).toBeInTheDocument()
  })

  it('renders different state of scopes with different selection values', () => {
    renderScopesGroup()

    fireEvent.click(screen.getByRole('button'))

    expect(screen.getByLabelText(/enable scope/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/disable scope/i)).toBeInTheDocument()
  })

  it('renders the scope group name', () => {
    renderScopesGroup()

    expect(screen.getByRole('button', {name: new RegExp(baseProps.name, 'i')})).toBeInTheDocument()
  })
})
