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

QUnit.module('DevelopersKeyApp');

test('displays the show more button', () => {
  const list = [...Array(10).keys()].map(n => ({id: `${n}`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z"}))

  const applicationState = {
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      list,
      nextPage: "http://..."
    },
  };

  const env = {
    developer_keys_count: 27
  }

  const component = TestUtils.renderIntoDocument(<DeveloperKeysApp applicationState={applicationState} actions={{}} env={env} />);
  const componentNode = ReactDOM.findDOMNode(component)
  ok(componentNode.innerHTML.includes("Show All 27 Keys"))
})

test('renders the list of developer_keys when there are some', () => {
  const applicationState = {
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
