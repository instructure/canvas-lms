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
import {shallow} from 'enzyme'
import merge from 'lodash/merge'
import Paginator from '../Paginator'

// Helper function to merge default props with overrides
const makeProps = (props = {}) =>
  merge(
    {
      page: 0,
      pageCount: 0,
      parent: {},
    },
    props
  )

describe('Paginator component', () => {
  test('renders the Paginator component', () => {
    const pager = shallow(<Paginator {...makeProps()} />)
    expect(pager.exists()).toBe(true)
  })

  test('renders empty when pageCount is 1', () => {
    const pager = shallow(<Paginator {...makeProps({page: 1, pageCount: 1})} />)
    expect(pager.text()).toBe('')
  })

  test('renders two pagination buttons when pageCount is 2', () => {
    const pager = shallow(<Paginator {...makeProps({page: 1, pageCount: 2})} />)
    expect(pager.find('PaginationButton').length).toBe(2)
  })
})
