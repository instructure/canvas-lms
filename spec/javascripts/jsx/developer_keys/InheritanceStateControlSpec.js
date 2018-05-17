/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute and/or modify under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import TestUtils from 'react-addons-test-utils'
import ReactDOM from 'react-dom'
import DeveloperKeyStateControl from 'jsx/developer_keys/InheritanceStateControl'

QUnit.module('InheritanceStateControl')

const rootAccountCTX = {
  params: {
    contextId: "1"
  }
}

const siteAdminCTX = {
  params: {
    contextId: "site_admin"
  }
}

function developerKey(workflowState, isOwnedByAccount) {
  return {
    developer_key_account_binding: {
      workflow_state: workflowState || 'off'
    },
    account_owns_binding: isOwnedByAccount || false
  }
}

function componentNode(key, context = rootAccountCTX) {
  const component = TestUtils.renderIntoDocument(<DeveloperKeyStateControl developerKey={key} ctx={context}/>)
  return ReactDOM.findDOMNode(component)
}

test('disables the radio group if the account does not own the binding and it is set', () => {
  const radioGroup = componentNode(developerKey('off')).querySelector('input[type="radio"]')
  ok(radioGroup.disabled)
})

test('enables the radio group if the account does not own the binding and it is not set', () => {
  const radioGroup = componentNode(developerKey('allow')).querySelector('input[type="radio"]')
  notOk(radioGroup.disabled)
})

test('enables the radio group if the account does the binding', () => {
  const radioGroup = componentNode(developerKey('allow', true)).querySelector('input[type="radio"]')
  notOk(radioGroup.disabled)
})

test('the correct state for the developer key', () => {
  const offRadioInput = componentNode(developerKey()).querySelector('input[value="off"]')
  ok(offRadioInput.checked)
})

test('renders "allow" if no binding is sent only for site_admin', () => {
  const modifiedKey = developerKey()
  modifiedKey.developer_key_account_binding = undefined
  const allowRadioInput = componentNode(modifiedKey, siteAdminCTX).querySelector('input[value="allow"]')
  ok(allowRadioInput.checked)
})

test('renders an "on" option', () => {
  ok(componentNode().querySelector('input[value="on"]'))
})

test('renders an "off" option', () => {
  ok(componentNode().querySelector('input[value="off"]'))
})

test('renders an "allow" option only for site_admin', () => {
  ok(componentNode(developerKey(), siteAdminCTX).querySelector('input[value="allow"]'))
})

test('do not render an "allow" option only for root-account', () => {
  notOk(componentNode(rootAccountCTX).querySelector('input[value="allow"]'))
})

test('renders "allow" if "allow" is set as the workflow state for site admin', () => {
  const allowRadioInput = componentNode(developerKey("allow"), siteAdminCTX).querySelector('input[value="allow"]')
  ok(allowRadioInput.checked)
})

test('renders "off" if "allow" is set as the workflow state for root account', () => {
  const offRadioInput = componentNode(developerKey("allow"), rootAccountCTX).querySelector('input[value="off"]')
  ok(offRadioInput.checked)
})
