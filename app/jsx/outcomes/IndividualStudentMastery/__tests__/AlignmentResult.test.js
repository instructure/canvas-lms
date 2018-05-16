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
import { render, shallow } from 'enzyme'
import AlignmentResult from '../AlignmentResult'

const defaultProps = (props = {}) => (
  Object.assign({
    outcome: {
      id: 1,
      mastered: false,
      ratings: [
        { description: 'My first rating' },
        { description: 'My second rating' }
      ],
      results: [],
      title: 'foo'
    },
    result: {
      id: 1,
      score: 1,
      percent: 0.1,
      alignment: {
        html_url: 'http://foo',
        name: 'My alignment'
      }
    }
  }, props)
)

it('renders the AlignmentResult component', () => {
  const wrapper = shallow(<AlignmentResult {...defaultProps()}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('includes the assignment name', () => {
  const wrapper = render(<AlignmentResult {...defaultProps()}/>)
  expect(wrapper.text()).toMatch('My alignment')
})

it('includes the ratings of the outcome', () => {
  const wrapper = render(<AlignmentResult {...defaultProps()}/>)
  expect(wrapper.text()).toMatch('My second rating')
})
