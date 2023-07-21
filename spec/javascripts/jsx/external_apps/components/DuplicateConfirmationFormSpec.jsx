/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import DuplicateConfirmationForm from 'ui/features/external_apps/react/components/DuplicateConfirmationForm'

let domNode

function renderComponent(props) {
  domNode = domNode || document.createElement('div')
  ReactDOM.render(<DuplicateConfirmationForm {...props} />, domNode)
}

const props = {
  onCancel: sinon.spy(),
  onSuccess: sinon.spy(),
  onError: sinon.spy(),
  toolData: {},
  configurationType: '',
  store: {},
}

QUnit.module('DuplicateConfirmationForm', {
  teardown() {
    document.querySelector('#fixtures').innerHTML = ''
  },
})

test('renders the component', () => {
  renderComponent(props)
  const component = domNode.querySelector('#duplicate-confirmation-form')
  ok(component)
})

test('calls the onCancel prop when the "cancel install" button is clicked', () => {
  renderComponent(props)
  const component = domNode.querySelector('#duplicate-confirmation-form')
  const button = domNode.querySelector('#cancel-install')
  TestUtils.Simulate.click(button)
  ok(props.onCancel.calledOnce)
})

test('calls the force install function if the "install anyway" button is clicked', () => {
  const saveSpy = sinon.spy()
  const propsDup = {...props}
  propsDup.store = {save: saveSpy}
  renderComponent(propsDup)
  const button = domNode.querySelector('#continue-install')
  TestUtils.Simulate.click(button)
  ok(saveSpy.calledOnce)
})

test('calls the force install prop if the "install anyway" button is clicked', () => {
  const saveSpy = sinon.spy()
  const propsDup = {forceSaveTool: saveSpy}
  renderComponent(propsDup)
  const button = domNode.querySelector('#continue-install')
  TestUtils.Simulate.click(button)
  ok(saveSpy.calledOnce)
})

test('sets "verifyUniqueness" to undefined when doing a force install', () => {
  const saveSpy = sinon.spy()
  const propsDup = {...props}
  propsDup.store = {save: saveSpy}
  renderComponent(propsDup)
  const button = domNode.querySelector('#continue-install')
  TestUtils.Simulate.click(button)
  equal(saveSpy.getCall(0).args[1].verifyUniqueness, undefined)
})
