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
import {render} from '@testing-library/react'
import merge from 'lodash/merge'
import Paginator from '../Paginator'

const makeProps = (props = {}) =>
  merge(
    {
      loadPage: jest.fn(),
      page: 0,
      pageCount: 0,
    },
    props,
  )

describe('Paginator component', () => {
  test('renders the Paginator component', () => {
    const {container} = render(<Paginator {...makeProps()} />)
    expect(container.firstChild).toBeInTheDocument()
  })

  test('renders empty when pageCount is 1', () => {
    const {container} = render(<Paginator {...makeProps({page: 1, pageCount: 1})} />)
    expect(container.firstChild).toBeEmptyDOMElement()
  })

  test('renders two pagination buttons when pageCount is 2', () => {
    const {getAllByRole} = render(<Paginator {...makeProps({page: 1, pageCount: 2})} />)
    const buttons = getAllByRole('button')
    expect(buttons).toHaveLength(2)
  })
})
