/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DeveloperKeysApp from '../App'

describe('DevelopersKeyApp', () => {
  const listDeveloperKeyScopes = {
    availableScopes: {},
    listDeveloperKeyScopesPending: false,
  }

  function generateKeyList(numKeys = 10) {
    return [...Array(numKeys).keys()].map(n => ({
      id: `${n}`,
      api_key: 'abc12345678',
      created_at: '2012-06-07T20:36:50Z',
      visible: true,
    }))
  }

  function initialApplicationState(list = null, inheritedList = null) {
    return {
      createOrEditDeveloperKey: {
        developerKeyCreateOrEditFailed: false,
        developerKeyCreateOrEditSuccessful: false,
        isLtiKey: false,
      },
      listDeveloperKeyScopes,
      listDeveloperKeys: {
        listDeveloperKeysPending: false,
        listDeveloperKeysSuccessful: true,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: true,
        inheritedList: inheritedList || [
          {
            id: '2',
            api_key: 'abc12345678',
            created_at: '2012-06-07T20:36:50Z',
            inherited_from: 'global',
            visible: true,
          },
        ],
        list: list || [
          {id: '1', api_key: 'abc12345678', created_at: '2012-06-07T20:36:50Z', visible: true},
        ],
        nextPage: 'http://...',
        inheritedNextPage: 'http://...',
      },
    }
  }

  function fakeStore() {
    return {
      dispatch: jest.fn(action => action),
    }
  }

  function renderComponent(overrides = {}) {
    const props = {
      applicationState: initialApplicationState(),
      actions: {
        developerKeysModalOpen: jest.fn(),
        createOrEditDeveloperKey: jest.fn(),
        developerKeysModalClose: jest.fn(),
        getRemainingDeveloperKeys: jest.fn(),
        getRemainingInheritedDeveloperKeys: jest.fn(),
        editDeveloperKey: jest.fn(),
        listDeveloperKeyScopesSet: jest.fn(),
        saveLtiToolConfiguration: jest.fn(),
        ltiKeysSetLtiKey: jest.fn(),
        resetLtiState: jest.fn(),
        updateLtiKey: jest.fn(),
        listDeveloperKeysReplace: jest.fn(),
        makeVisibleDeveloperKey: jest.fn(),
        setBindingWorkflowState: jest.fn(),
        makeInvisibleDeveloperKey: jest.fn(),
        activateDeveloperKey: jest.fn(),
        deactivateDeveloperKey: jest.fn(),
        deleteDeveloperKey: jest.fn(),
      },
      store: fakeStore(),
      ctx: {
        params: {
          contextId: 'test',
        },
      },
      ...overrides,
    }
    return render(<DeveloperKeysApp {...props} />)
  }

  test('only renders inherited keys in the inherited tab', async () => {
    const {getByRole, findByRole} = renderComponent()

    // Click inherited tab
    const inheritedTab = getByRole('tab', {name: 'Inherited'})
    await userEvent.click(inheritedTab)

    // Since we set listInheritedDeveloperKeysSuccessful: true, table should be available immediately
    const table = await findByRole('table', {name: /Global Inherited Developer Keys/})
    const rows = within(table).getAllByRole('row')
    expect(rows).toHaveLength(2) // Header row + one data row
  })

  test('renders the correct keys in the account tab', async () => {
    const {findByRole} = renderComponent()

    // Since we set listDeveloperKeysSuccessful: true, table should be available immediately
    const table = await findByRole('table')
    expect(within(table).getByText('1')).toBeInTheDocument()
  })

  test('only renders account keys in the account tab', async () => {
    const {findByRole} = renderComponent()

    // Since we set listDeveloperKeysSuccessful: true, table should be available immediately
    const table = await findByRole('table')
    const rows = within(table).getAllByRole('row')
    expect(rows).toHaveLength(2) // Header row + one data row
  })

  test('renders the account keys tab', () => {
    const {getByRole} = renderComponent()

    const accountTab = getByRole('tab', {name: 'Account'})
    expect(accountTab).toHaveAttribute('aria-selected', 'true')
  })

  test('renders the inherited keys tab', () => {
    const {getByRole} = renderComponent()

    const inheritedTab = getByRole('tab', {name: 'Inherited'})
    expect(inheritedTab).toBeInTheDocument()
  })

  test('displays the show more button', () => {
    const list = generateKeyList()
    const applicationState = {
      listDeveloperKeyScopes,
      createOrEditDeveloperKey: {
        developerKeyCreateOrEditFailed: false,
        developerKeyCreateOrEditSuccessful: false,
        isLtiKey: false,
      },
      listDeveloperKeys: {
        listDeveloperKeysPending: false,
        listDeveloperKeysSuccessful: true,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: true,
        inheritedList: [],
        list,
        nextPage: 'http://...',
      },
    }

    const {getByText} = renderComponent({applicationState})
    expect(getByText('Show All Keys')).toBeInTheDocument()
  })

  test('renders the list of developer_keys when there are some', async () => {
    const applicationState = {
      listDeveloperKeyScopes,
      createOrEditDeveloperKey: {
        developerKeyCreateOrEditFailed: false,
        developerKeyCreateOrEditSuccessful: false,
        isLtiKey: false,
      },
      listDeveloperKeys: {
        listDeveloperKeysPending: false,
        listDeveloperKeysSuccessful: true,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: true,
        inheritedList: [],
        list: [
          {
            id: '111',
            api_key: 'abc12345678',
            created_at: '2012-06-07T20:36:50Z',
            visible: true,
          },
        ],
      },
    }

    const {findByRole} = renderComponent({applicationState})
    const table = await findByRole('table')
    expect(within(table).getByText('111')).toBeInTheDocument()
  })

  test('displays the spinner when loading', () => {
    const applicationState = {
      listDeveloperKeyScopes,
      createOrEditDeveloperKey: {
        developerKeyCreateOrEditFailed: false,
        developerKeyCreateOrEditSuccessful: false,
        isLtiKey: false,
      },
      listDeveloperKeys: {
        listDeveloperKeysPending: true,
        listDeveloperKeysSuccessful: false,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: false,
        inheritedList: [],
        list: [],
      },
    }

    const {getByText} = renderComponent({applicationState})
    expect(getByText('Loading')).toBeInTheDocument()
  })

  test('does not have the create button on inherited tab', async () => {
    const {getByRole, queryByRole} = renderComponent()

    // Click inherited tab
    const inheritedTab = getByRole('tab', {name: 'Inherited'})
    await userEvent.click(inheritedTab)

    // Check that there's no create button
    expect(queryByRole('button', {name: /Create Developer Key/i})).not.toBeInTheDocument()
  })
})
