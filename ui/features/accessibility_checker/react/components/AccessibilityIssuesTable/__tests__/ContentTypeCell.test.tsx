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

import {render, screen} from '@testing-library/react'

import {ContentTypeCell} from '../ContentTypeCell'
import {ContentItemType, ContentItem} from '../../../types'

describe('ContentTypeCell', () => {
  it('renders "Page"', () => {
    render(<ContentTypeCell item={{type: ContentItemType.WikiPage} as ContentItem} />)
    expect(screen.getByText('Page')).toBeInTheDocument()
  })

  it('renders "Assignment"', () => {
    render(<ContentTypeCell item={{type: ContentItemType.Assignment} as ContentItem} />)
    expect(screen.getByText('Assignment')).toBeInTheDocument()
  })

  it('renders "Attachment"', () => {
    render(<ContentTypeCell item={{type: ContentItemType.Attachment} as ContentItem} />)
    expect(screen.getByText('Attachment')).toBeInTheDocument()
  })
})
