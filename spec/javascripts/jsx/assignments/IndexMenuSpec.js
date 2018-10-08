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
import Modal from 'react-modal'
import IndexMenu from 'jsx/assignments/IndexMenu'
import Actions from 'jsx/assignments/actions/IndexMenuActions'
import createFakeStore from './createFakeStore'

QUnit.module('AssignmentsIndexMenu')

const generateProps = (overrides, initialState = {}) => {
  const state = {
    externalTools: [],
    selectedTool: null,
    ...initialState
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
    ...overrides
  }
}

const renderComponent = props => TestUtils.renderIntoDocument(<IndexMenu {...props} />)

const context = {}

const beforeEach = () => {
  context.sinon = sinon.sandbox.create()
  context.sinon.stub(Actions, 'apiGetLaunches').returns({
    type: 'STUB_API_GET_TOOLS'
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

testCase('renders a LTI tool modal', () => {
  const component = renderComponent(generateProps({}))

  const modals = TestUtils.scryRenderedComponentsWithType(component, Modal)
  equal(modals.length, 1)
  component.closeModal()
  ReactDOM.unmountComponentAtNode(component.node.parentElement)
})

testCase('Modal visibility agrees with state modalIsOpen', () => {
  const component1 = renderComponent(generateProps({}, {modalIsOpen: true}))
  const modal1 = TestUtils.findRenderedComponentWithType(component1, Modal)
  equal(modal1.props.isOpen, true)

  const component2 = renderComponent(generateProps({}, {modalIsOpen: false}))
  const modal2 = TestUtils.findRenderedComponentWithType(component2, Modal)
  equal(modal2.props.isOpen, false)
  component1.closeModal()
  component2.closeModal()
  ReactDOM.unmountComponentAtNode(component1.node.parentElement)
  ReactDOM.unmountComponentAtNode(component2.node.parentElement)
})

testCase('renders no iframe when there is no selectedTool in state', () => {
  const component = renderComponent(generateProps({}, {selectedTool: null}))
  const iframes = TestUtils.scryRenderedDOMComponentsWithTag(component, 'iframe')
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
          definition_id: 100
        }
      }
    )
  )

  const modal = TestUtils.findRenderedComponentWithType(component, Modal)
  const modalPortal = modal.portal

  const iframes = TestUtils.scryRenderedDOMComponentsWithTag(modalPortal, 'iframe')
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
