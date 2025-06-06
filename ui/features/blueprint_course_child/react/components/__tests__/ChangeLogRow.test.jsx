/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import ChangeLogRow, {ChangeRow} from '../ChangeLogRow'
import getSampleData from '@canvas/blueprint-courses/getSampleData'

describe('ChangeLogRow component', () => {
  const defaultProps = () => ({
    col1: 'col #1',
    col2: 'col #2',
    col3: 'col #3',
    col4: 'col #4',
    isHeading: false,
  })

  test('renders the ChangeLogRow component', () => {
    const {container} = render(<ChangeLogRow {...defaultProps()} />)
    const node = container.querySelector('.bcs__history-item__change-log-row')
    expect(node).toBeTruthy()
  })

  test('renders the ChangeLogRow component as a heading', () => {
    const props = defaultProps()
    props.isHeading = true
    const {container} = render(<ChangeLogRow {...props} />)
    const node = container.querySelector('.bcs__history-item__change-log-row__heading')
    expect(node).toBeTruthy()
  })

  test('renders children inside content', () => {
    const children = <div className="test-children" />
    const {container} = render(<ChangeLogRow {...defaultProps()}>{children}</ChangeLogRow>)
    const node = container.querySelector('.bcs__history-item__content .test-children')
    expect(node).toBeTruthy()
  })

  test('renders the ChangeRow component', () => {
    const {container} = render(<ChangeRow change={getSampleData().history[0].changes[0]} />)
    const node = container.querySelector('.bcs__history-item__change-log-row')
    expect(node).toBeTruthy()
  })

  test('renders lock icon when its a ChangeRow component', () => {
    const {container} = render(<ChangeRow change={getSampleData().history[0].changes[0]} />)
    const node = container.querySelector(
      '.bcs__history-item__content .bcs__history-item__lock-icon',
    )
    expect(node).toBeTruthy()
  })
})
