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
import DashboardCardBox from 'jsx/dashboard_card/DashboardCardBox'
import CourseActivitySummaryStore from 'jsx/dashboard_card/CourseActivitySummaryStore'

QUnit.module('DashboardCardBox', {
  setup() {
    this.stub(CourseActivitySummaryStore, 'getStateForCourse').returns({})
    this.courseCards = [
      {
        id: 1,
        shortName: 'Bio 101'
      },
      {
        id: 2,
        shortName: 'Philosophy 201'
      }
    ]
  },
  teardown() {
    localStorage.clear()
    if (this.component) {
      ReactDOM.unmountComponentAtNode(this.component.getDOMNode().parentNode)
    }
  }
})

test('should render div.ic-DashboardCard per provided courseCard', function() {
  const CardBox = <DashboardCardBox courseCards={this.courseCards} />
  this.component = TestUtils.renderIntoDocument(CardBox)
  const $html = $(this.component.getDOMNode())
  equal($html.children('div.ic-DashboardCard').length, this.courseCards.length)
})
