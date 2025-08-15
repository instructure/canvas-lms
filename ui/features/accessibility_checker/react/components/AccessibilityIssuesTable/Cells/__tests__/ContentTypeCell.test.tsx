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
import {AccessibilityResourceScan, ResourceType} from '../../../../types'

describe('ContentTypeCell', () => {
  it('renders "Page"', () => {
    render(
      <ContentTypeCell item={{resourceType: ResourceType.WikiPage} as AccessibilityResourceScan} />,
    )
    expect(screen.getByText('Page')).toBeInTheDocument()
  })

  it('renders "Assignment"', () => {
    render(
      <ContentTypeCell
        item={{resourceType: ResourceType.Assignment} as AccessibilityResourceScan}
      />,
    )
    expect(screen.getByText('Assignment')).toBeInTheDocument()
  })

  it('renders "Attachment"', () => {
    render(
      <ContentTypeCell
        item={{resourceType: ResourceType.Attachment} as AccessibilityResourceScan}
      />,
    )
    expect(screen.getByText('Attachment')).toBeInTheDocument()
  })
})
