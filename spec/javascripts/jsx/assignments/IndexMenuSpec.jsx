/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {Modal} from '@instructure/ui-modal'
import IndexMenu from 'ui/features/assignment_index/react/IndexMenu'
import Actions from 'ui/features/assignment_index/react/actions/IndexMenuActions'
import createFakeStore from './createFakeStore'
import {handleDeepLinking} from '@canvas/deep-linking/DeepLinking'
import $ from 'jquery'

QUnit.module('AssignmentsIndexMenu')

const generateProps = (overrides, initialState = {}) => {
  const state = {
    externalTools: [],
    selectedTool: null,
    ...initialState,
  }
  return {
    store: createFakeStore(state),
    contextType: 'course',
    contextId: 1,
    setTrigger: () => {},
    setDisableTrigger: () => {},
    registerWeightToggle: () => {},
    disableSyncToSis: () => {},
    sisName: 'PowerSchool',
    postToSisDefault: ENV.POST_TO_SIS_DEFAULT,
    hasAssignments: ENV.HAS_ASSIGNMENTS,
    ...overrides,
  }
}

const renderComponent = props => TestUtils.renderIntoDocument(<IndexMenu {...props} />)

const context = {}

const beforeEach = () => {
  context.sinon = sinon.createSandbox()
  context.sinon.stub(Actions, 'apiGetLaunches').returns({
    type: 'STUB_API_GET_TOOLS',
  })
}

const afterEach = () => {
  context.sinon.restore()
}

const testCase = (msg, testFunc) => {
  beforeEach()
  test(msg, testFunc)
  afterEach()
}

testCase('renders a dropdown menu trigger and options list', () => {
  const component = renderComponent(generateProps({}))

  const triggers = TestUtils.scryRenderedDOMComponentsWithClass(component, 'al-trigger')
  equal(triggers.length, 1)

  const options = TestUtils.scryRenderedDOMComponentsWithClass(component, 'al-options')
  equal(options.length, 1)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('renders a bulk edit option if property is specified', () => {
  const requestBulkEditFn = sinon.stub()
  const component = renderComponent(generateProps({requestBulkEdit: requestBulkEditFn}))

  const menuitem = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'requestBulkEditMenuItem'
  )
  equal(menuitem.length, 1)
  TestUtils.Simulate.click(menuitem[0])
  ok(requestBulkEditFn.called)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('does not render a bulk edit option if property is not specified', () => {
  const component = renderComponent(generateProps())
  const menuitem = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'requestBulkEditMenuItem'
  )
  equal(menuitem.length, 0)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

// Skipped for FOO-3190 ... the TestUtils methods don't work well for
// matching against InstUI components as of V8. Recommend rewriting
// this entire test in Jest and React Testing Library
QUnit.skip('renders an LTI tool modal', () => {
  const component = renderComponent(generateProps({}, {modalIsOpen: true}))

  const modals = TestUtils.scryRenderedComponentsWithType(component, Modal)
  equal(modals.length, 1)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

// Skipped for FOO-3190 ... the TestUtils methods don't work well for
// matching against InstUI components as of V8. Recommend rewriting
// this entire test in Jest and React Testing Library
QUnit.skip('Modal visibility agrees with state modalIsOpen', () => {
  const component1 = renderComponent(generateProps({}, {modalIsOpen: true}))
  const modal1 = TestUtils.findRenderedComponentWithType(component1, Modal)
  equal(modal1.props.open, true)

  const component2 = renderComponent(generateProps({}, {modalIsOpen: false}))
  equal(TestUtils.scryRenderedComponentsWithType(component2, Modal).length, 0)
  component1.closeModal()
  component2.closeModal()
  ReactDOM.unmountComponentAtNode(component1.node.parentElement)
  ReactDOM.unmountComponentAtNode(component2.node.parentElement)
})

testCase('renders no iframe when there is no selectedTool in state', () => {
  const component = renderComponent(generateProps({}, {selectedTool: null}))

  const iframes = component.node.ownerDocument.body.querySelectorAll('iframe')
  equal(iframes.length, 0)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('renders iframe when there is a selectedTool in state', () => {
  const component = renderComponent(
    generateProps(
      {},
      {
        modalIsOpen: true,
        selectedTool: {
          placements: {course_assignments_menu: {title: 'foo'}},
          definition_id: 100,
        },
      }
    )
  )
  const iframes = component.node.ownerDocument.body.querySelectorAll('iframe')
  equal(iframes.length, 1)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('onWeightedToggle dispatches expected actions', () => {
  const props = generateProps({})
  const store = props.store
  const component = renderComponent(props)
  const actionsCount = store.dispatchedActions.length

  component.onWeightedToggle(true)
  equal(store.dispatchedActions.length, actionsCount + 1)
  equal(store.dispatchedActions[actionsCount].type, Actions.SET_WEIGHTED)
  equal(store.dispatchedActions[actionsCount].payload, true)

  component.onWeightedToggle(false)
  equal(store.dispatchedActions.length, actionsCount + 2)
  equal(store.dispatchedActions[actionsCount + 1].type, Actions.SET_WEIGHTED)
  equal(store.dispatchedActions[actionsCount + 1].payload, false)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('renders a dropdown menu with one option when sync to sis conditions are not met', () => {
  const component = renderComponent(generateProps({}))
  const options = TestUtils.scryRenderedDOMComponentsWithTag(component, 'li')

  equal(options.length, 1)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('renders a dropdown menu with two options when sync to sis conditions are met', () => {
  ENV.POST_TO_SIS_DEFAULT = true
  ENV.HAS_ASSIGNMENTS = true
  const component = renderComponent(generateProps({}))
  const options = TestUtils.scryRenderedDOMComponentsWithTag(component, 'li')

  equal(options.length, 2)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('renders a dropdown menu with one option when sync to sis conditions are not met', () => {
  ENV.POST_TO_SIS_DEFAULT = true
  ENV.HAS_ASSIGNMENTS = false
  const component = renderComponent(generateProps({}))
  const options = TestUtils.scryRenderedDOMComponentsWithTag(component, 'li')

  equal(options.length, 1)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('reloads the page when receiving a deep linking message', async () => {
  ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'https://www.test.com'
  ENV.FEATURES = {
    lti_multiple_assignment_deep_linking: true,
  }
  const message = overrides => ({
    origin: 'https://www.test.com',
    data: {subject: 'LtiDeepLinkingResponse'},
    ...overrides,
  })
  const initialState = {modalIsOpen: true}
  const component = renderComponent(generateProps({}, initialState))
  const reloadPage = sinon.stub()
  await handleDeepLinking(reloadPage)(message())

  ok(reloadPage.calledOnce)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('reloads the page when assignment_index_menu receives externalContentReady', async () => {
  ENV.assignment_index_menu_tools = [
    {id: '1', title: 'test', base_url: 'https://example.com/launch'},
  ]
  $('#fixtures').append("<div id='external-tool-mount-point'></div>")

  const mockWindow = {
    location: {
      reload: sinon.stub(),
    },
  }
  const component = renderComponent(generateProps({currentWindow: mockWindow}))
  const links = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a')

  // open tray
  TestUtils.Simulate.click(links[links.length - 1])

  // trigger event
  $(window).trigger('externalContentReady')

  ok(mockWindow.location.reload.calledOnce)

  ReactDOM.unmountComponentAtNode(component.node.parentElement)
  $('#fixtures').empty()
})
