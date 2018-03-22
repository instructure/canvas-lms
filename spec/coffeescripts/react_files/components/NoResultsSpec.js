/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import $ from 'jquery'
import NoResults from 'jsx/files/NoResults'

QUnit.module('NoResults')

test('displays search term in no results text', () => {
  const noResults = React.createFactory(NoResults)
  const search_term = 'texas toast'
  const rendered = TestUtils.renderIntoDocument(noResults({search_term}))
  equal(
    rendered.refs.yourSearch.props.children,
    `Your search - \"${search_term}\" - did not match any files.`,
    'has the right text'
  )
  ReactDOM.unmountComponentAtNode(rendered.getDOMNode().parentNode)
})
