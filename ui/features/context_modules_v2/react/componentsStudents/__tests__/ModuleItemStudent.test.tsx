/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import ModuleItemStudent, {ModuleItemStudentProps} from '../ModuleItemStudent'

const setUp = (props: ModuleItemStudentProps) => {
  return render(<ModuleItemStudent {...props} />)
}

const buildDefaultProps = (overrides = {}) => {
  const defaultProps: ModuleItemStudentProps = {
    _id: '1',
    url: 'https://canvas.instructure.com/courses/1/assignments/1',
    indent: 0,
    position: 0,
    requireSequentialProgress: false,
    index: 0,
    content: {
      id: '1',
      _id: '1',
      title: 'Test Item',
      type: 'Assignment',
      url: 'https://canvas.instructure.com/courses/1/assignments/1',
    },
  }

  return {...defaultProps, ...overrides}
}

describe('ModuleItemStudent', () => {
  it('renders null if no content is provided', () => {
    const {container} = setUp(buildDefaultProps({content: null as any}))
    expect(container).toBeEmptyDOMElement()
  })

  it('renders a module item', () => {
    const {container} = setUp(buildDefaultProps())
    expect(container).not.toBeEmptyDOMElement()
  })

  it('renders locked styling when sequential progression is required and current position < item position', () => {
    const progression = {
      completedAt: null,
      currentPosition: 1,
      locked: false,
      requirementsMet: [],
      state: 'unlocked',
    }

    const container = setUp(
      buildDefaultProps({
        requireSequentialProgress: true,
        position: 2,
        progression,
      }),
    )

    const titleElement = container.getByTestId('module-item-title-locked')
    expect(titleElement).toBeInTheDocument()
  })

  it('renders normal styling when sequential progression is required but position is accessible', () => {
    const progression = {
      completedAt: null,
      currentPosition: 2,
      locked: false,
      requirementsMet: [],
      state: 'unlocked',
    }

    const container = setUp(
      buildDefaultProps({
        requireSequentialProgress: true,
        position: 1,
        progression,
      }),
    )

    const titleElement = container.getByTestId('module-item-title')
    expect(titleElement).toBeInTheDocument()
  })

  it('renders unlocked styling when sequential progression is required and current position = item position', () => {
    const progression = {
      completedAt: null,
      currentPosition: 1,
      locked: false,
      requirementsMet: [],
      state: 'unlocked',
    }

    const container = setUp(
      buildDefaultProps({
        requireSequentialProgress: true,
        position: 1,
        progression,
      }),
    )

    const titleElement = container.getByTestId('module-item-title')
    expect(titleElement).toBeInTheDocument()
  })

  it('renders subheader title without extra info', () => {
    const container = setUp(
      buildDefaultProps({
        content: {
          id: '1',
          _id: '1',
          title: 'Test Item',
          type: 'SubHeader',
          url: 'https://canvas.instructure.com/courses/1/assignments/1',
        },
      }),
    )

    const titleElement = container.getByTestId('subheader-title-text')
    expect(titleElement).toBeInTheDocument()
    expect(container.queryByTestId('module-item-supplemental-info')).toBeNull()
    expect(container.queryByTestId('module-item-status-icon')).toBeNull()
  })
})
