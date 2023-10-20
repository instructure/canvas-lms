/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import ImportantDateItem from '../ImportantDateItem'

describe('ImportantDateItem', () => {
  const getProps = (overrides = {}) => ({
    id: '1',
    title: 'Paper',
    context: 'English',
    color: '#AAABBB',
    type: 'text_entry',
    url: 'http://localhost/paper',
    ...overrides,
  })

  it('renders the context name', () => {
    const {getByText} = render(<ImportantDateItem {...getProps()} />)
    expect(getByText('English')).toBeInTheDocument()
  })

  it('renders the item title with link', () => {
    const {getByRole} = render(<ImportantDateItem {...getProps()} />)
    const link = getByRole('link', {name: 'Paper'})
    expect(link).toBeInTheDocument()
    expect(link.href).toBe('http://localhost/paper')
  })

  it('renders the icon in the correct color', () => {
    const {getByTestId} = render(<ImportantDateItem {...getProps()} />)
    const icon = getByTestId('date-icon-wrapper')
    expect(icon).toBeInTheDocument()
    expect(icon).toHaveStyle('color: #AAABBB')
  })

  describe('item icon', () => {
    it('is labeled Calendar Event if type is event', () => {
      const {getByText} = render(<ImportantDateItem {...getProps({type: 'event'})} />)
      expect(getByText('Calendar Event')).toBeInTheDocument()
    })

    it('is labeled Discussion if type is discussion_topic', () => {
      const {getByText} = render(<ImportantDateItem {...getProps({type: 'discussion_topic'})} />)
      expect(getByText('Discussion')).toBeInTheDocument()
    })

    it('is labeled Quiz if type is online_quiz', () => {
      const {getByText} = render(<ImportantDateItem {...getProps({type: 'online_quiz'})} />)
      expect(getByText('Quiz')).toBeInTheDocument()
    })

    it('is labeled Assignment if type is something else', () => {
      const {getByText} = render(<ImportantDateItem {...getProps()} />)
      expect(getByText('Assignment')).toBeInTheDocument()
    })
  })
})
