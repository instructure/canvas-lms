/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ChildChangeLog from '../ChildChangeLog'
import loadStates from '@canvas/blueprint-courses/react/loadStates'
import getSampleData from '@canvas/blueprint-courses/getSampleData'

const defaultProps = () => ({
  status: loadStates.states.not_loaded,
  migration: getSampleData().history[0],
})

describe('ChildChangeLog component', () => {
  test('renders the ChildChangeLog component', () => {
    const {container} = render(<ChildChangeLog {...defaultProps()} />)
    const node = container.querySelector('.bcc__change-log')
    expect(node).toBeInTheDocument()
  })

  test('renders loading indicator if in loading state', () => {
    const props = defaultProps()
    props.status = loadStates.states.loading
    const {container} = render(<ChildChangeLog {...props} />)
    const node = container.querySelector('.bcc__change-log__loading')
    expect(node).toBeInTheDocument()
  })

  test('renders history item when in loaded state', () => {
    const props = defaultProps()
    props.status = loadStates.states.loaded
    const {container} = render(<ChildChangeLog {...props} />)
    const node = container.querySelector('.bcs__history-item')
    expect(node).toBeInTheDocument()
  })

  test('does not render history item when in loading state', () => {
    const props = defaultProps()
    props.status = loadStates.states.loading
    const {container} = render(<ChildChangeLog {...props} />)
    const node = container.querySelector('.bcs__history-item')
    expect(node).not.toBeInTheDocument()
  })
})
