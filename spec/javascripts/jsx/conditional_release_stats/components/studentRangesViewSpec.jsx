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
import RangesView from '@canvas/conditional-release-stats/react/components/student-ranges-view'

const container = document.getElementById('fixtures')

QUnit.module('Student Ranges View', {
  teardown() {
    ReactDOM.unmountComponentAtNode(container)
  },
})

const defaultProps = () => ({
  ranges: [
    {
      scoring_range: {
        id: 1,
        rule_id: 1,
        lower_bound: 0.7,
        upper_bound: 1.0,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
    {
      scoring_range: {
        id: 3,
        rule_id: 1,
        lower_bound: 0.4,
        upper_bound: 0.7,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
    {
      scoring_range: {
        id: 2,
        rule_id: 1,
        lower_bound: 0.0,
        upper_bound: 0.4,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
  ],
  assignment: {
    id: 7,
    title: 'Points',
    description: '',
    points_possible: 15,
    grading_type: 'points',
    submission_types: 'on_paper',
    grading_scheme: null,
  },
  selectedPath: {
    range: 0,
    student: null,
  },
  loadStudent: () => {},
  selectRange: () => {},
  selectStudent: () => {},
})

// using ReactDOM instead of TestUtils to render because of InstUI
const renderComponent = props => ReactDOM.render(<RangesView {...props} />, container)

// skip if webpack: CNVS-33473
if (window.hasOwnProperty('define')) {
  test('renders three ranges components correctly', () => {
    renderComponent(defaultProps())

    const tabs = document.querySelectorAll('[role="tab"]')
    equal(tabs.length, 3, 'renders full component')

    const tabPanels = document.querySelectorAll('[role="tabpanel"]')
    equal(tabPanels.length, 3, 'renders full component')

    // Accordion only renders the currently open tab, so we only check for the first tab's content
    ok(document.querySelector('[role="tabpanel"] .crs-student-range'))
  })
} else {
  QUnit.skip('renders three ranges components correctly')
}
