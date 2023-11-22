/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import MoveToDialog from '../MoveToDialog'
import React from 'react'
import {render} from '@testing-library/react'

describe('MoveToDialog', () => {
  const props = {
    header: 'This is a dialog',
    source: {label: 'foo', id: '0'},
    destinations: [
      {label: 'bar', id: '1'},
      {label: 'baz', id: '2'},
    ],
    onMove: () => {},
    onClose: () => {},
    triggerElement: document.createElement('div'),
    appElement: document.createElement('div'),
  }

  it('renders the prop header', () => {
    const {getByText} = render(<MoveToDialog {...props} />)
    expect(getByText('This is a dialog')).toBeInTheDocument()
  })

  it('identifies the page that is currently selected', () => {
    const {getByText} = render(<MoveToDialog {...props} />)
    expect(getByText('Place "foo" before:')).toBeInTheDocument()
  })

  it('includes all destinations in select', () => {
    const {getByText} = render(<MoveToDialog {...props} />)
    const select = document.body.querySelector('select')

    expect(select).toBeInTheDocument()
    expect(select).toContainElement(getByText('bar'))
    expect(select).toContainElement(getByText('baz'))
  })

  it('includes "at the bottom" in select', () => {
    const {getByText} = render(<MoveToDialog {...props} />)
    const select = document.body.querySelector('select')

    expect(select).toBeInTheDocument()
    expect(select).toContainElement(getByText('-- At the bottom --'))
  })
})
