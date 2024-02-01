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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import {Spinner} from '@instructure/ui-spinner'
import {mount} from 'enzyme'

import DeveloperKeysApp from 'ui/features/developer_keys_v2/react/App'

QUnit.module('DevelopersKeyApp', {
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  },
  beforeEach: () => {
    window.ENV = {
      FEATURES: {
        lti_dynamic_registration: true,
      },
    }
  },
  afterEach: () => {
    window.ENV = {}
  },
})

const listDeveloperKeyScopes = {
  availableScopes: {},
  listDeveloperKeyScopesPending: false,
}

function developerKeyRows(componentNode, index) {
  const panel = componentNode.querySelectorAll("div[role='tabpanel']")[index]
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
  }))
}

function initialApplicationState(list = null, inheritedList = null) {
  return {
    createOrEditDeveloperKey: {isLtiKey: false},
    listDeveloperKeyScopes,
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      inheritedList: inheritedList || [
        {
          id: 2,
          api_key: 'abc12345678',
          created_at: '2012-06-07T20:36:50Z',
          inherited_from: 'global',
        },
      ],
      list: list || [{id: 1, api_key: 'abc12345678', created_at: '2012-06-07T20:36:50Z'}],
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
    actions: {},
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
    },
  }
  const component = renderComponent(overrides)
  const componentNode = ReactDOM.findDOMNode(component)

  clickInheritedTab(componentNode)
  clickShowAllButton(componentNode, 1)

  ok(callbackSpy.called)
})

test('requests more account dev keys when the account "show all" button is clicked', () => {
  const callbackSpy = sinon.spy()
  const overrides = {
    applicationState: initialApplicationState(generateKeyList()),
    actions: {
      getRemainingDeveloperKeys: () => () => ({}),
    },
  }
  const component = renderComponent(overrides)
  const componentNode = ReactDOM.findDOMNode(component)
  component.mainTableRef.setFocusCallback = callbackSpy

  clickShowAllButton(componentNode)
  ok(callbackSpy.called)
})

test('calls the tables setFocusCallback after loading more account keys', () => {
  const callbackSpy = sinon.spy()
  const overrides = {
    applicationState: initialApplicationState(generateKeyList()),
    actions: {
      getRemainingDeveloperKeys: () => () => ({
        then: callbackSpy,
      }),
    },
  }
  const component = renderComponent(overrides)
  const componentNode = ReactDOM.findDOMNode(component)
  const focusSpy = sinon.spy()
  component.mainTableRef.setFocusCallback = focusSpy

  clickShowAllButton(componentNode)

  ok(focusSpy.called)
})

test('calls the tables setFocusCallback after loading more inherited keys', () => {
  const callbackSpy = sinon.spy()
  const overrides = {
    applicationState: initialApplicationState(generateKeyList(), generateKeyList()),
    actions: {
      getRemainingInheritedDeveloperKeys: () => () => ({
        then: callbackSpy,
      }),
    },
  }
  const component = renderComponent(overrides)
  const componentNode = ReactDOM.findDOMNode(component)
  const focusSpy = sinon.spy()

  clickInheritedTab(componentNode)
  component.inheritedTableRef.setFocusCallback = focusSpy

  clickShowAllButton(componentNode, 1)

  ok(focusSpy.called)
})

test('renders the correct keys in the inherited tab', () => {
  const component = renderComponent()
  const componentNode = ReactDOM.findDOMNode(component)
  clickInheritedTab(componentNode)
  ok(
    Array.from(inheritedDeveloperKeyRows(componentNode, 1)[1].querySelectorAll('td div')).some(
      n => n.innerText === '2'
    )
  )
})

test('only renders inherited keys in the inherited tab', () => {
  const component = renderComponent()
  const componentNode = ReactDOM.findDOMNode(component)
  clickInheritedTab(componentNode)
  equal(inheritedDeveloperKeyRows(componentNode, 1).length, 2)
})

test('renders the correct keys in the account tab', () => {
  const component = renderComponent()
  const componentNode = ReactDOM.findDOMNode(component)
  ok(
    Array.from(developerKeyRows(componentNode, 0)[1].querySelectorAll('td div')).some(
      n => n.innerText === '1'
    )
  )
})

test('only renders account keys in the account tab', () => {
  const component = renderComponent()
  const componentNode = ReactDOM.findDOMNode(component)

  equal(developerKeyRows(componentNode, 0).length, 2)
})

test('renders the account keys tab', () => {
  const component = renderComponent()
  const componentNode = ReactDOM.findDOMNode(component)

  equal(componentNode.querySelector('div[role="tab"][aria-selected="true"]').textContent, 'Account')
})

test('renders the inherited keys tab', () => {
  const component = renderComponent()
  const componentNode = ReactDOM.findDOMNode(component)

  equal(componentNode.querySelectorAll('div[role="tab"]')[1].textContent, 'Inherited')
})

test('displays the show more button', () => {
  const list = generateKeyList()

  const applicationState = {
    listDeveloperKeyScopes,
    createOrEditDeveloperKey: {isLtiKey: false},
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      list,
      nextPage: 'http://...',
    },
  }

  const component = renderComponent({applicationState})
  const componentNode = ReactDOM.findDOMNode(component)

  ok(componentNode.innerHTML.includes('Show All Keys'))
})

test('renders the list of developer_keys when there are some', () => {
  const applicationState = {
    listDeveloperKeyScopes,
    createOrEditDeveloperKey: {isLtiKey: false},
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      list: [
        {
          id: '111',
          api_key: 'abc12345678',
          created_at: '2012-06-07T20:36:50Z',
        },
      ],
    },
  }

  const component = renderComponent({applicationState})
  const renderedText = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithTag(component, 'table')
  ).innerHTML
  ok(renderedText.includes('111'))
})

test('displays the developer key on click of show key button', () => {
  const applicationState = {
    listDeveloperKeyScopes,
    createOrEditDeveloperKey: {isLtiKey: false},
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      list: [
        {
          id: '111',
          api_key: 'abc12345678',
          created_at: '2012-06-07T20:36:50Z',
        },
      ],
    },
  }
  const props = {
    applicationState,
    actions: {developerKeysModalOpen: () => {}},
    store: fakeStore(),
    ctx: {
      params: {
        contextId: '',
      },
    },
  }
  const wrapper = mount(<DeveloperKeysApp {...props} />)

  const btn = wrapper.find({'data-testid': 'show-key'}).first()
  ok(btn.html().includes('Show Key'))
  btn.simulate('click')
  ok(btn.html().includes('Hide Key'))
  wrapper.unmount()
})

test('renders the spinner', () => {
  const overrides = {
    listDeveloperKeyScopes,
    createOrEditDeveloperKey: {isLtiKey: false},
    listDeveloperKeys: {
      listDeveloperKeysPending: true,
      listDeveloperKeysSuccessful: false,
      list: [
        {
          id: '111',
          api_key: 'abc12345678',
          created_at: '2012-06-07T20:36:50Z',
        },
      ],
    },
  }

  const props = {
    applicationState: {
      ...initialApplicationState(),
      ...overrides,
    },
    actions: {},
    store: fakeStore(),
    ctx: {
      params: {
        contextId: '',
      },
    },
  }
  const wrapper = mount(<DeveloperKeysApp {...props} />)
  const spinner = wrapper.find(Spinner)
  ok(spinner.exists())
})

test('does not have the create button on inherited tab', () => {
  const openSpy = sinon.spy()

  const overrides = {
    applicationState: {
      listDeveloperKeyScopes,
      createOrEditDeveloperKey: {isLtiKey: false},
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
    },
  }

  const component = renderComponent(overrides)
  const componentNode = ReactDOM.findDOMNode(component)
  clickInheritedTab(componentNode)
  const button = componentNode.querySelector('.ic-Action-header__Secondary button')

  notOk(button)
})
