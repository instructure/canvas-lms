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
import fakeENV from 'helpers/fakeENV'
import CyoeStats from 'jsx/conditional_release_stats/index'

const defaultEnv = () => ({
  ranges: [
    {
      scoring_range: {
        id: 1,
        rule_id: 1,
        lower_bound: 0.7,
        upper_bound: 1.0,
        created_at: null,
        updated_at: null,
        position: null
      },
      size: 0,
      students: []
    },
    {
      scoring_range: {
        id: 3,
        rule_id: 1,
        lower_bound: 0.4,
        upper_bound: 0.7,
        created_at: null,
        updated_at: null,
        position: null
      },
      size: 0,
      students: []
    },
    {
      scoring_range: {
        id: 2,
        rule_id: 1,
        lower_bound: 0.0,
        upper_bound: 0.4,
        created_at: null,
        updated_at: null,
        position: null
      },
      size: 0,
      students: []
    }
  ],
  enrolled: 10,
  assignment: {
    id: 7,
    title: 'Points',
    description: '',
    points_possible: 15,
    grading_type: 'points',
    submission_types: 'on_paper',
    grading_scheme: null
  },
  isLoading: false,
  selectRange: () => {}
})

let testNode = null

QUnit.module('CyoeStats - init', {
  setup() {
    fakeENV.setup()
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = defaultEnv()
    ENV.current_user_roles = ['teacher']
    ENV.CONDITIONAL_RELEASE_ENV.rule = {}

    testNode = document.createElement('div')
    document.getElementById('fixtures').appendChild(testNode)
  },

  teardown() {
    fakeENV.teardown()
    document.getElementById('fixtures').removeChild(testNode)
    testNode = null
  }
})

class IndexSpecContainer extends React.Component {
  render() {
    return (
      <div>
        <div className="test-details" />
        <div className="test-graphs" />
      </div>
    )
  }
}

const prepDocument = () => ReactDOM.render(<IndexSpecContainer />, testNode)

const testRender = expectedToRender => {
  const doc = prepDocument()
  const graphsRoot = TestUtils.findRenderedDOMComponentWithClass(doc, 'test-graphs')
  const detailsParent = TestUtils.findRenderedDOMComponentWithClass(doc, 'test-details')
  CyoeStats.init(graphsRoot, detailsParent)

  const childCount = expectedToRender ? 1 : 0
  const renderedGraphs = graphsRoot.getElementsByClassName('crs-breakdown-graph')
  equal(renderedGraphs.length, childCount)
}

test('adds the react components in the correct places', () => {
  testRender(true)
})

test('does not add components when mastery paths not enabled', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  testRender(false)
})

test('does not add if there is not a rule defined', () => {
  ENV.CONDITIONAL_RELEASE_ENV.rule = null
  testRender(false)
})
