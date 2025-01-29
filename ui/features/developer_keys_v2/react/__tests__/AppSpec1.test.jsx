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
import {render, within, waitFor} from '@testing-library/react'
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

  test('requests more inherited dev keys when the inherited "show all" button is clicked', async () => {
    const callbackSpy = jest.fn()
    const store = fakeStore()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList(), generateKeyList(20)),
      actions: {
        getRemainingInheritedDeveloperKeys: () => callbackSpy,
        developerKeysModalOpen: jest.fn(),
        createOrEditDeveloperKey: jest.fn(),
        developerKeysModalClose: jest.fn(),
        getRemainingDeveloperKeys: jest.fn(),
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
      store,
      ctx: {
        params: {
          contextId: 'test',
        },
      },
    }
    const {getByRole, findByTestId} = renderComponent(overrides)

    // Click inherited tab
    const inheritedTab = getByRole('tab', {name: 'Inherited'})
    await userEvent.click(inheritedTab)

    // Wait for the tab to be selected
    await waitFor(() => {
      expect(inheritedTab).toHaveAttribute('aria-selected', 'true')
    })

    // Click show all button
    const showAllButton = await findByTestId('show-all-inherited')
    await userEvent.click(showAllButton)

    // Verify callback was called
    expect(callbackSpy).toHaveBeenCalled()
  })

  test('requests more account dev keys when the account "show all" button is clicked', async () => {
    const callbackSpy = jest.fn()
    const store = fakeStore()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList()),
      actions: {
        getRemainingDeveloperKeys: () => callbackSpy,
        developerKeysModalOpen: jest.fn(),
        createOrEditDeveloperKey: jest.fn(),
        developerKeysModalClose: jest.fn(),
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
      store,
      ctx: {
        params: {
          contextId: 'test',
        },
      },
    }
    const {getByTestId} = renderComponent(overrides)

    // Click show all button
    const showAllButton = getByTestId('show-all-account')
    await userEvent.click(showAllButton)

    // Verify callback was called
    expect(callbackSpy).toHaveBeenCalled()
  })

  test('calls the tables setFocusCallback after loading more account keys', async () => {
    const callbackSpy = jest.fn()
    const store = fakeStore()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList()),
      actions: {
        getRemainingDeveloperKeys: () => () => {
          callbackSpy()
          return {then: () => {}}
        },
        developerKeysModalOpen: jest.fn(),
        createOrEditDeveloperKey: jest.fn(),
        developerKeysModalClose: jest.fn(),
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
      store,
      ctx: {
        params: {
          contextId: 'test',
        },
      },
    }
    const {getByTestId} = renderComponent(overrides)

    // Click show all button
    const showAllButton = getByTestId('show-all-account')
    await userEvent.click(showAllButton)

    // Verify callback was called
    expect(callbackSpy).toHaveBeenCalled()
  })

  test('calls the tables setFocusCallback after loading more inherited keys', async () => {
    const callbackSpy = jest.fn()
    const store = fakeStore()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList(), generateKeyList()),
      actions: {
        getRemainingInheritedDeveloperKeys: () => () => {
          callbackSpy()
          return {then: () => {}}
        },
        developerKeysModalOpen: jest.fn(),
        createOrEditDeveloperKey: jest.fn(),
        developerKeysModalClose: jest.fn(),
        getRemainingDeveloperKeys: jest.fn(),
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
      store,
      ctx: {
        params: {
          contextId: 'test',
        },
      },
    }
    const {getByRole, findByTestId} = renderComponent(overrides)

    // Click inherited tab
    const inheritedTab = getByRole('tab', {name: 'Inherited'})
    await userEvent.click(inheritedTab)

    // Wait for the tab to be selected
    await waitFor(() => {
      expect(inheritedTab).toHaveAttribute('aria-selected', 'true')
    })

    // Click show all button
    const showAllButton = await findByTestId('show-all-inherited')
    await userEvent.click(showAllButton)

    // Verify callback was called
    expect(callbackSpy).toHaveBeenCalled()
  })
})
