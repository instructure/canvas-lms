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
import {render, screen} from '@testing-library/react'
import TagInfo, {TagData, TagInfoProps} from '../TagInfo'

describe('TagInfo Component', () => {
  const renderComponent = (props: Partial<TagInfoProps> = {}) => {
    const defaultProps: TagInfoProps = {
      tags: [],
    }
    return render(<TagInfo {...defaultProps} {...props} />)
  }

  it('renders the tag count when a single tag is provided', () => {
    const singleTag: TagData[] = [{id: 1, name: 'Variant A', members_count: 15}]
    renderComponent({tags: singleTag})

    expect(screen.getByText('15 students')).toBeInTheDocument()
    expect(screen.getByText('15 students')).toHaveAttribute('aria-hidden', 'true')
  })

  it('renders multiple tags with counts', async () => {
    const multipleTags: TagData[] = [
      {id: 1, name: 'Variant A', members_count: 10},
      {id: 2, name: 'Variant B', members_count: 20},
      {id: 3, name: 'Variant C', members_count: 30},
    ]
    renderComponent({tags: multipleTags})

    multipleTags.forEach(tag => {
      expect(screen.getByText(tag.name)).toBeInTheDocument()
      expect(screen.getByTestId('tag-' + tag.name)).toHaveAttribute(
        'aria-label',
        `${tag.name} - ${tag.members_count} students`,
      )
      expect(screen.getByText(`${tag.members_count} students`)).toBeInTheDocument()
      expect(screen.getByText(`${tag.members_count} students`)).toHaveAttribute(
        'aria-hidden',
        'true',
      )
    })
  })
})
