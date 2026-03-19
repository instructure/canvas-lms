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
import {AccessibilityResourceScan, ResourceType} from '../../../../../../shared/react/types'

describe('ContentTypeCell', () => {
  describe('text rendering', () => {
    it('renders "Page" for WikiPage resource type', () => {
      render(
        <ContentTypeCell
          item={{resourceType: ResourceType.WikiPage} as AccessibilityResourceScan}
        />,
      )
      expect(screen.getByText('Page')).toBeInTheDocument()
    })

    it('renders "Assignment" for Assignment resource type', () => {
      render(
        <ContentTypeCell
          item={{resourceType: ResourceType.Assignment} as AccessibilityResourceScan}
        />,
      )
      expect(screen.getByText('Assignment')).toBeInTheDocument()
    })

    it('renders "Attachment" for Attachment resource type', () => {
      render(
        <ContentTypeCell
          item={{resourceType: ResourceType.Attachment} as AccessibilityResourceScan}
        />,
      )
      expect(screen.getByText('Attachment')).toBeInTheDocument()
    })

    it('renders "Discussion Topic" for DiscussionTopic resource type', () => {
      render(
        <ContentTypeCell
          item={{resourceType: ResourceType.DiscussionTopic} as AccessibilityResourceScan}
        />,
      )
      expect(screen.getByText('Discussion topic')).toBeInTheDocument()
    })

    it('renders "Announcement" for Announcement resource type', () => {
      render(
        <ContentTypeCell
          item={{resourceType: ResourceType.Announcement} as AccessibilityResourceScan}
        />,
      )
      expect(screen.getByText('Announcement')).toBeInTheDocument()
    })
  })

  describe('icon rendering', () => {
    it('renders document icon for WikiPage', () => {
      const {container} = render(
        <ContentTypeCell
          item={{resourceType: ResourceType.WikiPage} as AccessibilityResourceScan}
        />,
      )
      const icon = container.querySelector('svg[name="IconDocument"]')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('aria-hidden', 'true')
    })

    it('renders assignment icon for Assignment', () => {
      const {container} = render(
        <ContentTypeCell
          item={{resourceType: ResourceType.Assignment} as AccessibilityResourceScan}
        />,
      )
      const icon = container.querySelector('svg[name="IconAssignment"]')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('aria-hidden', 'true')
    })

    it('renders MS Word icon for Attachment', () => {
      const {container} = render(
        <ContentTypeCell
          item={{resourceType: ResourceType.Attachment} as AccessibilityResourceScan}
        />,
      )
      const icon = container.querySelector('svg[name="IconMsWord"]')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('aria-hidden', 'true')
    })

    it('renders discussion icon for DiscussionTopic', () => {
      const {container} = render(
        <ContentTypeCell
          item={{resourceType: ResourceType.DiscussionTopic} as AccessibilityResourceScan}
        />,
      )
      const icon = container.querySelector('svg[name="IconDiscussion"]')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('aria-hidden', 'true')
    })

    it('renders announcement icon for Announcement', () => {
      const {container} = render(
        <ContentTypeCell
          item={{resourceType: ResourceType.Announcement} as AccessibilityResourceScan}
        />,
      )
      const icon = container.querySelector('svg[name="IconAnnouncement"]')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('aria-hidden', 'true')
    })
  })

  describe('layout', () => {
    it('renders icon and text in a flex layout', () => {
      const {container} = render(
        <ContentTypeCell
          item={{resourceType: ResourceType.DiscussionTopic} as AccessibilityResourceScan}
        />,
      )
      const flexContainer = container.querySelector('[class*="flex"]')
      expect(flexContainer).toBeInTheDocument()
    })
  })
})
