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
import {shallow} from 'enzyme'
import SyncHistoryItem from '../SyncHistoryItem'
import getSampleData from './getSampleData'

describe('SyncHistoryItem component', () => {
  const defaultProps = () => ({
    heading: null,
    migration: getSampleData().history[0],
  })

  test('renders the SyncHistoryItem component', () => {
    const tree = shallow(<SyncHistoryItem {...defaultProps()} />)
    const node = tree.find('.bcs__history-item')
    expect(node).toBeTruthy()
  })

  test('renders heading component when migration has changes', () => {
    const props = defaultProps()
    props.heading = <p className="test-heading">test</p>
    const tree = shallow(<SyncHistoryItem {...props} />)
    const node = tree.find('.bcs__history-item .test-heading')
    expect(node).toBeTruthy()
  })

  test('does not render the heading component when migration has no changes', () => {
    const props = defaultProps()
    props.heading = <p className="test-heading">test</p>
    props.migration.changes = []
    const tree = shallow(<SyncHistoryItem {...props} />)
    const node = tree.find('.bcs__history-item .test-heading')
    expect(node.exists()).toBeFalsy()
  })

  test('renders changes using the appropriate prop component', () => {
    const props = defaultProps()
    props.ChangeComponent = () => <div className="test-change" />
    const tree = render(<SyncHistoryItem {...props} />)
    const node = tree.container.querySelectorAll('.bcs__history-item .test-change')
    expect(node.length).toEqual(props.migration.changes.length)
  })

  test('includes the name of the person who started the sync', () => {
    const tree = render(<SyncHistoryItem {...defaultProps()} />)
    const node = tree.container.querySelector('.bcs__history-item__title')
    const text = node.textContent
    expect(text.indexOf('changes pushed by Bob Jones')).toEqual(57)
  })
})
