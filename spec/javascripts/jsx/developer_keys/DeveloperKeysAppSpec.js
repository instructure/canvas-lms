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
import TestUtils from 'react-addons-test-utils'
import DeveloperKeysApp from 'jsx/developer_keys/DeveloperKeysApp';

QUnit.module('DevelopersKeyApp',  {
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  }
});

function developerKeyRows(componentNode, index) {
  const panel = componentNode.querySelectorAll("div[role='tabpanel']")[index]
  return panel.querySelectorAll("table#keys tr")
}

function generateKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({id: `${n}`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z"}))
}

function initialApplicationState(list = null, inheritedList = null) {
  return {
    createOrEditDeveloperKey: {},
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      inheritedList: inheritedList || [{id: 2, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z"}],
      list: list || [{id: 1, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z"}],
      nextPage: "http://...",
      inheritedNextPage: 'http://...'
    },
  };
}

function fakeStore() {
  return {
    dispatch: () => {}
  }
}

function clickInheritedTab(componentNode) {
  const [,inheritedTab] = componentNode.querySelectorAll("div[role='tab']")
  TestUtils.Simulate.click(inheritedTab)
}

test('requests more inherited dev keys when the inherited "show all" button is clicked', () => {
  const list = generateKeyList()
  const inheritedList = generateKeyList(20)
  const applicationState = initialApplicationState(list, inheritedList)
  const getRemainingInheritedDeveloperKeysSpy = sinon.spy()
  const fakeActions = {
    getRemainingInheritedDeveloperKeys: getRemainingInheritedDeveloperKeysSpy
  }
  const component = TestUtils.renderIntoDocument(
    <DeveloperKeysApp applicationState={applicationState} actions={fakeActions} store={fakeStore()}/>
  );
  const componentNode = ReactDOM.findDOMNode(component)

  clickInheritedTab(componentNode)

  const button = componentNode.querySelectorAll("div[role='tabpanel']")[1].querySelector('button')
  TestUtils.Simulate.click(button);

  ok(getRemainingInheritedDeveloperKeysSpy.called)
})

test('requests more account dev keys when the account "show all" button is clicked', () => {
  const list = generateKeyList()

  const applicationState = initialApplicationState(list)
  const getRemainingDeveloperKeysSpy = sinon.spy()
  const fakeActions = {
    getRemainingDeveloperKeys: getRemainingDeveloperKeysSpy
  }
  const component = TestUtils.renderIntoDocument(
    <DeveloperKeysApp applicationState={applicationState} actions={fakeActions} store={fakeStore()}/>
  );
  const componentNode = ReactDOM.findDOMNode(component)

  const button = componentNode.querySelectorAll("div[role='tabpanel']")[0].querySelector('button')
  TestUtils.Simulate.click(button);

  ok(getRemainingDeveloperKeysSpy.called)
})

test('calls the tables focusLastDeveloperKey after loading more account keys', () => {
  const list = generateKeyList()
  const applicationState = initialApplicationState(list)
  const fakeActions = {
    getRemainingDeveloperKeys: () => {}
  }
  const component = TestUtils.renderIntoDocument(
    <DeveloperKeysApp applicationState={applicationState} actions={fakeActions} store={fakeStore()}/>
  );
  const componentNode = ReactDOM.findDOMNode(component)
  const focusSpy = sinon.spy()
  component.mainTableRef.focusLastDeveloperKey = focusSpy

  const button = componentNode.querySelectorAll("div[role='tabpanel']")[0].querySelector('button')
  TestUtils.Simulate.click(button);

  ok(focusSpy.called)
})

test('calls the tables focusLastDeveloperKey after loading more inherited keys', () => {
  const list = generateKeyList()
  const inheritedList = generateKeyList()

  const applicationState = initialApplicationState(list, inheritedList)
  const fakeActions = {
    getRemainingInheritedDeveloperKeys: () => {}
  }
  const component = TestUtils.renderIntoDocument(
    <DeveloperKeysApp applicationState={applicationState} actions={fakeActions} store={fakeStore()}/>
  );
  const componentNode = ReactDOM.findDOMNode(component)
  const focusSpy = sinon.spy()

  clickInheritedTab(componentNode)
  component.inheritedTableRef.focusLastDeveloperKey = focusSpy

  const button = componentNode.querySelectorAll("div[role='tabpanel']")[1].querySelector('button')
  TestUtils.Simulate.click(button);

  ok(focusSpy.called)
})

test('renders the correct keys in the inherited tab', () => {
  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={initialApplicationState()} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)
  clickInheritedTab(componentNode)
  equal(developerKeyRows(componentNode, 1)[1].querySelector('.details div').innerHTML, 2)
})

test('only renders inherited keys in the inherited tab', () => {
  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={initialApplicationState()} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)
  clickInheritedTab(componentNode)
  equal(developerKeyRows(componentNode, 1).length, 2)
})

test('renders the correct keys in the account tab', () => {
  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={initialApplicationState()} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)
  equal(developerKeyRows(componentNode, 0)[1].querySelector('.details div').innerHTML, 1)
})

test('only renders account keys in the account tab', () => {
  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={initialApplicationState()} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)

  equal(developerKeyRows(componentNode, 0).length, 2)
})

test('renders the account keys tab', () => {
  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={initialApplicationState()} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)

  equal(componentNode.querySelector('div[role="tab"][aria-selected="true"]').textContent, "Account")
})

test('renders the inherited keys tab', () => {
  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={initialApplicationState()} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)

  equal(componentNode.querySelectorAll('div[role="tab"]')[1].textContent, "Inherited")
})

test('displays the show more button', () => {
  const list = generateKeyList()

  const applicationState = {
    createOrEditDeveloperKey: {},
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      list,
      nextPage: "http://..."
    },
  };

  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={applicationState} actions={{}}/>);
  const componentNode = ReactDOM.findDOMNode(component)

  ok(componentNode.innerHTML.includes("Show All Keys"))
})
test('renders the list of developer_keys when there are some', () => {
  const applicationState = {
    createOrEditDeveloperKey: {},
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      list: [
        {
          id: "111",
          api_key: "abc12345678",
          created_at: "2012-06-07T20:36:50Z"
        }
      ]
    },
  };

  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={applicationState} actions={{}} />);
  const renderedText = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithTag(component, 'table')).innerHTML;
  ok(renderedText.includes("abc12345678"))
})

test('renders the spinner', () => {
  const applicationState = {
    createOrEditDeveloperKey: {},
    listDeveloperKeys: {
      listDeveloperKeysPending: true,
      listDeveloperKeysSuccessful: false,
      list: [
        {
          id: "111",
          api_key: "abc12345678",
          created_at: "2012-06-07T20:36:50Z"
        }
      ]
    },
  };

  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={applicationState} actions={{}} />);

  const renderedText = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithTag(component, 'svg')).innerHTML;

  ok(renderedText.includes("Loading"))
})

test('opens the modal when the create button is clicked', () => {
  const openSpy = sinon.spy()

  const applicationState = {
    createOrEditDeveloperKey: {},
    listDeveloperKeys: {
      listDeveloperKeysPending: true,
      listDeveloperKeysSuccessful: false,
      list: [
        {
          id: "111",
          api_key: "abc12345678",
          created_at: "2012-06-07T20:36:50Z"
        }
      ]
    },
  };

  const fakeStore = {
    dispatch: () => {}
  }

  const fakeActions = {
    developerKeysModalOpen: openSpy
  }

  const component = TestUtils.renderIntoDocument(
    <DeveloperKeysApp
      applicationState={applicationState}
      actions={fakeActions}
      store={ fakeStore }
    />
  );
  const componentNode = ReactDOM.findDOMNode(component)
  const button = componentNode.querySelector('.ic-Action-header__Secondary button')
  TestUtils.Simulate.click(button)

  ok(openSpy.called)
})
