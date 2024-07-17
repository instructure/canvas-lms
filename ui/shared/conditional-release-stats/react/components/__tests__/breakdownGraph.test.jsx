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
import TestUtils from 'react-dom/test-utils'
import BreakdownGraph from '../breakdown-graphs'

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
  enrolled: 10,
  assignment: {
    id: 7,
    title: 'Points',
    description: '',
    points_possible: 15,
    grading_type: 'points',
    submission_types: 'on_paper',
    grading_scheme: null,
  },
  isLoading: false,
  selectRange: () => {},
  openSidebar: () => {},
})

const renderComponent = props => TestUtils.renderIntoDocument(<BreakdownGraph {...props} />)

describe('Breakdown Graph', () => {
  test('renders three bar components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
      component,
      'crs-bar__container'
    )
    expect(renderedList.length).toBe(3)
  })

  test('renders bar inner-components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-link-button')
    expect(renderedList.length).toBe(3)
  })

  test('renders lower bound correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    expect(renderedList[2].textContent).toBe('0 pts+ to 6 pts')
  })

  test('renders upper bound correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    expect(renderedList[0].textContent).toBe('10.5 pts+ to 15 pts')
  })

  test('renders enrolled correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-link-button')
    expect(renderedList[0].textContent).toBe('0 out of 10 students')
  })
})
