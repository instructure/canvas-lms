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
import TestUtils from 'react-addons-test-utils'
import ReactDOM from 'react-dom'
import DeveloperKey from 'jsx/developer_keys/DeveloperKey';

class TestTable extends React.Component {
  render () {
    return (<table><tbody>{this.props.children}</tbody></table>)
  }
}

function makeTable (keyProps) {
  return (<TestTable><DeveloperKey {...keyProps} /></TestTable>)
}

function testWrapperOk (keyProps, expectedString) {
  const component = TestUtils.renderIntoDocument(makeTable(keyProps));
  const renderedText = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithTag(component, 'tr')).innerHTML;
  ok(renderedText.includes(expectedString))
}

function testWrapperNotOk (keyProps, expectedString) {
  const component = TestUtils.renderIntoDocument(makeTable(keyProps));
  const renderedText = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithTag(component, 'tr')).innerHTML;
  notOk(renderedText.includes(expectedString))
}

function props() {
  return {
    developerKey: {
      access_token_count: 77,
      account_name: "bob account",
      api_key: "rYcJ7LnUbSAuxiMh26tXTSkaYWyfRPh2lr6FqTLqx0FRsmv44EVZ2yXC8Rgtabc3",
      created_at: "2018-02-09T20:36:50Z",
      email: "bob@myemail.com",
      icon_url: "http://my_image.com",
      id: "10000000000004",
      last_used_at: "2018-06-07T20:36:50Z",
      name: "Atomic fireball",
      notes: "all the notas",
      redirect_uri: "http://my_redirect_uri.com",
      redirect_uris: "",
      user_id: "53532",
      user_name: "billy bob",
      vendor_code: "b3w9w9bf",
      workflow_state: "active",
    }
  }
}

QUnit.module('DeveloperKey');
test('includes developerName', () => {
  testWrapperOk(props(), "Atomic fireball")
});

test('includes Unnamed Tool when developerName us null', () => {
  const propsModified = props()
  propsModified.developerKey.name = null
  testWrapperOk(propsModified, "Unnamed Tool")
});

test('includes Unnamed Tool when developerName empty string case', () => {
  const propsModified = props()
  propsModified.developerKey.name = ""
  testWrapperOk(propsModified, "Unnamed Tool")
});

test('includes userName', () => {
  testWrapperOk(props(), "billy bob")
});

test('includes No User when userName is null', () => {
  const propsModified = props()
  propsModified.developerKey.user_name = null
  testWrapperOk(propsModified, "No User")
});

test('includes No User when userName is empty string', () => {
  const propsModified = props()
  propsModified.developerKey.user_name = ""
  testWrapperOk(propsModified, "No User")
});

test('includes an image when name is present', () => {
  testWrapperOk(props(), '<img class="icon" src="http://my_image.com" alt="Atomic fireball Logo"')
});

test('includes an image when name is not present', () => {
  const propsModified = props()
  propsModified.developerKey.name = null
  testWrapperOk(propsModified, '<img class="icon" src="http://my_image.com" alt="Unnamed Tool Logo"')
});

test('includes a blank image when icon_url is null', () => {
  const propsModified = props()
  propsModified.developerKey.icon_url = null
  testWrapperOk(propsModified, '<img class="icon" src="#" alt=""')
});

test('includes a blank image when icon_url is empty string', () => {
  const propsModified = props()
  propsModified.developerKey.icon_url = ''
  testWrapperOk(propsModified, '<img class="icon" src="#" alt=""')
});

test('does not inactive when workflow_state is active', () => {
  testWrapperNotOk(props(), 'inactive')
});

test('includes a user link', () => {
  testWrapperOk(props(), '<a href="/users/53532"')
  testWrapperOk(props(), '>billy bob</a>')
});

test('does not include a user link when user_id is null', () => {
  const propsModified = props()
  propsModified.developerKey.user_id = null
  testWrapperNotOk(propsModified, '<a href="/users/53532"')
  testWrapperNotOk(propsModified, '>billy bob</a>')
  testWrapperOk(propsModified, 'billy bob')
});

test('includes a redirect_uri', () => {
  testWrapperOk(props(), 'URI:')
  testWrapperOk(props(), 'http://my_redirect_uri.com')
});

test('does not include a redirect_uri when redirect_uri is null', () => {
  const propsModified = props()
  propsModified.developerKey.redirect_uri = null
  testWrapperNotOk(propsModified, 'URI:')
});

test('includes a last_used_at', () => {
  testWrapperOk(props(), "2018-06-07T20:36:50Z")
});

test('includes "Never" when last_used_at is null', () => {
  const propsModified = props()
  propsModified.developerKey.last_used_at = null
  testWrapperOk(propsModified, 'Never')
});

