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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import sinon from 'sinon'

import DeveloperKeysApp from '../App'

describe('DevelopersKeyApp', () => {
  const listDeveloperKeyScopes = {
    availableScopes: {},
    listDeveloperKeyScopesPending: false,
  }

  function developerKeyRows(componentNode, index) {
    const panel = componentNode.querySelectorAll("div[role='tabpanel']")[index]
    // console.log(panel.innerHTML)
    // console.log(panel.querySelectorAll("table[data-automation='devKeyAdminTable'] tr").length)
    return panel.querySelectorAll("table[data-automation='devKeyAdminTable'] tr")
  }

  function inheritedDeveloperKeyRows(componentNode, index) {
    const panel = componentNode.querySelectorAll("div[role='tabpanel']")[index]
    return panel.querySelectorAll("table[data-automation='devKeyInheritedTable'] tr")
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
        listDeveloperKeysSuccessful: false,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: false,
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
      dispatch: () => {},
    }
  }

  function clickInheritedTab(componentNode) {
    const [, inheritedTab] = componentNode.querySelectorAll("div[role='tab']")
    TestUtils.Simulate.click(inheritedTab)
  }

  function clickShowAllButton(componentNode, panel = 0) {
    const buttons = componentNode
      .querySelectorAll("div[role='tabpanel']")
      [panel].querySelectorAll('button')
    TestUtils.Simulate.click(buttons[buttons.length - 1])
  }

  function renderComponent(overrides = {}) {
    const props = {
      applicationState: initialApplicationState(),
      actions: {
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingDeveloperKeys: () => {},
        getRemainingInheritedDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
      store: fakeStore(),
      ctx: {
        params: {
          contextId: '',
        },
      },
      ...overrides,
    }
    return TestUtils.renderIntoDocument(<DeveloperKeysApp {...props} />)
  }

  test('requests more inherited dev keys when the inherited "show all" button is clicked', () => {
    const callbackSpy = sinon.spy()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList(), generateKeyList(20)),
      actions: {
        getRemainingInheritedDeveloperKeys: () => callbackSpy,
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
    }
    const component = renderComponent(overrides)
    const componentNode = ReactDOM.findDOMNode(component)

    clickInheritedTab(componentNode)
    clickShowAllButton(componentNode, 1)

    expect(callbackSpy.called).toBeTruthy()
  })

  test('requests more account dev keys when the account "show all" button is clicked', () => {
    const callbackSpy = sinon.spy()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList()),
      actions: {
        getRemainingDeveloperKeys: () => () => ({}),
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingInheritedDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
    }
    const component = renderComponent(overrides)
    const componentNode = ReactDOM.findDOMNode(component)
    component.mainTableRef.setFocusCallback = callbackSpy

    clickShowAllButton(componentNode)
    expect(callbackSpy.called).toBeTruthy()
  })

  test('calls the tables setFocusCallback after loading more account keys', () => {
    const callbackSpy = sinon.spy()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList()),
      actions: {
        getRemainingDeveloperKeys: () => () => ({
          then: callbackSpy,
        }),
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingInheritedDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
    }
    const component = renderComponent(overrides)
    const componentNode = ReactDOM.findDOMNode(component)
    const focusSpy = sinon.spy()
    component.mainTableRef.setFocusCallback = focusSpy

    clickShowAllButton(componentNode)

    expect(focusSpy.called).toBeTruthy()
  })

  test('calls the tables setFocusCallback after loading more inherited keys', () => {
    const callbackSpy = sinon.spy()
    const overrides = {
      applicationState: initialApplicationState(generateKeyList(), generateKeyList()),
      actions: {
        getRemainingInheritedDeveloperKeys: () => () => ({
          then: callbackSpy,
        }),
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
    }
    const component = renderComponent(overrides)
    const componentNode = ReactDOM.findDOMNode(component)
    const focusSpy = sinon.spy()

    clickInheritedTab(componentNode)
    component.inheritedTableRef.setFocusCallback = focusSpy

    clickShowAllButton(componentNode, 1)

    expect(focusSpy.called).toBeTruthy()
  })

  test('renders the correct keys in the inherited tab', () => {
    const component = renderComponent()
    const componentNode = ReactDOM.findDOMNode(component)
    clickInheritedTab(componentNode)
    expect(
      Array.from(inheritedDeveloperKeyRows(componentNode, 1)[1].querySelectorAll('td div')).some(
        n => n.textContent === '2'
      )
    ).toBeTruthy()
  })

  test('only renders inherited keys in the inherited tab', () => {
    const component = renderComponent()
    const componentNode = ReactDOM.findDOMNode(component)
    clickInheritedTab(componentNode)
    expect(inheritedDeveloperKeyRows(componentNode, 1).length).toEqual(2)
  })

  test('renders the correct keys in the account tab', () => {
    const component = renderComponent()
    const componentNode = ReactDOM.findDOMNode(component)
    expect(
      Array.from(developerKeyRows(componentNode, 0)[1].querySelectorAll('td div')).some(
        n => n.textContent === '1'
      )
    ).toBeTruthy()
  })

  test('only renders account keys in the account tab', () => {
    const component = renderComponent()
    const componentNode = ReactDOM.findDOMNode(component)

    expect(developerKeyRows(componentNode, 0).length).toEqual(2)
  })

  test('renders the account keys tab', () => {
    const component = renderComponent()
    const componentNode = ReactDOM.findDOMNode(component)

    expect(
      componentNode.querySelector('div[role="tab"][aria-selected="true"]').textContent
    ).toEqual('Account')
  })

  test('renders the inherited keys tab', () => {
    const component = renderComponent()
    const componentNode = ReactDOM.findDOMNode(component)

    expect(componentNode.querySelectorAll('div[role="tab"]')[1].textContent).toEqual('Inherited')
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
        listDeveloperKeysSuccessful: false,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: false,
        inheritedList: [],
        list,
        nextPage: 'http://...',
      },
    }

    const component = renderComponent({applicationState})
    const componentNode = ReactDOM.findDOMNode(component)

    expect(componentNode.innerHTML.includes('Show All Keys')).toBeTruthy()
  })

  test('renders the list of developer_keys when there are some', () => {
    const applicationState = {
      listDeveloperKeyScopes,
      createOrEditDeveloperKey: {
        developerKeyCreateOrEditFailed: false,
        developerKeyCreateOrEditSuccessful: false,
        isLtiKey: false,
      },
      listDeveloperKeys: {
        listDeveloperKeysPending: false,
        listDeveloperKeysSuccessful: false,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: false,
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

    const component = renderComponent({applicationState})
    const renderedText = ReactDOM.findDOMNode(
      TestUtils.findRenderedDOMComponentWithTag(component, 'table')
    ).innerHTML
    expect(renderedText.includes('111')).toBeTruthy()
  })

  test('displays the developer key on click of show key button', async () => {
    const applicationState = {
      listDeveloperKeyScopes,
      createOrEditDeveloperKey: {
        developerKeyCreateOrEditFailed: false,
        developerKeyCreateOrEditSuccessful: false,
        isLtiKey: false,
      },
      listDeveloperKeys: {
        listDeveloperKeysPending: false,
        listDeveloperKeysSuccessful: false,
        listInheritedDeveloperKeysPending: false,
        listInheritedDeveloperKeysSuccessful: false,
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
    const props = {
      applicationState,
      actions: {
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingDeveloperKeys: () => {},
        getRemainingInheritedDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
      store: fakeStore(),
      ctx: {
        params: {
          contextId: '',
        },
      },
    }
    const wrapper = render(<DeveloperKeysApp {...props} />)

    const btn = wrapper.container.querySelector('[data-testid="show-key"]')
    expect(btn.innerHTML.includes('Show Key')).toBeTruthy()
    const user = userEvent.setup({delay: null})
    await user.click(btn)
    expect(btn.innerHTML.includes('Hide Key')).toBeTruthy()
  })

  test('renders the spinner', () => {
    const overrides = {
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

    const props = {
      applicationState: {
        ...initialApplicationState(),
        ...overrides,
      },
      actions: {
        developerKeysModalOpen: () => {},
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingDeveloperKeys: () => {},
        getRemainingInheritedDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
      store: fakeStore(),
      ctx: {
        params: {
          contextId: '',
        },
      },
    }
    const wrapper = render(<DeveloperKeysApp {...props} />)
    const spinner = wrapper.container.querySelector('circle')
    expect(spinner).toBeTruthy()
  })

  test('does not have the create button on inherited tab', () => {
    const openSpy = sinon.spy()

    const overrides = {
      applicationState: {
        listDeveloperKeyScopes,
        createOrEditDeveloperKey: {
          developerKeyCreateOrEditFailed: false,
          developerKeyCreateOrEditSuccessful: false,
          isLtiKey: false,
        },
        listDeveloperKeys: {
          listInheritedDeveloperKeysPending: true,
          listInheritedDeveloperKeysSuccessful: false,
          listDeveloperKeysPending: true,
          listDeveloperKeysSuccessful: false,
          list: [],
          inheritedList: [
            {
              id: '111',
              api_key: 'abc12345678',
              created_at: '2012-06-07T20:36:50Z',
            },
          ],
        },
      },
      actions: {
        developerKeysModalOpen: openSpy,
        createOrEditDeveloperKey: () => {},
        developerKeysModalClose: () => {},
        getRemainingDeveloperKeys: () => {},
        getRemainingInheritedDeveloperKeys: () => {},
        editDeveloperKey: () => {},
        listDeveloperKeyScopesSet: () => {},
        saveLtiToolConfiguration: () => {},
        ltiKeysSetLtiKey: () => {},
        resetLtiState: () => {},
        updateLtiKey: () => {},
        listDeveloperKeysReplace: () => {},
        makeVisibleDeveloperKey: () => {},
        setBindingWorkflowState: () => {},
        makeInvisibleDeveloperKey: () => {},
        activateDeveloperKey: () => {},
        deactivateDeveloperKey: () => {},
        deleteDeveloperKey: () => {},
      },
    }

    const component = renderComponent(overrides)
    const componentNode = ReactDOM.findDOMNode(component)
    clickInheritedTab(componentNode)
    const button = componentNode.querySelector('.ic-Action-header__Secondary button')

    expect(button).toBeFalsy()
  })
})
