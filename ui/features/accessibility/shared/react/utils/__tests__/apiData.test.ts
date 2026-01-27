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

import {
  convertKeysToCamelCase,
  getAsContentItem,
  getAsContentItemType,
  getAsAccessibilityResourceScan,
} from '../apiData'
import {
  AccessibilityResourceScan,
  ContentItem,
  ContentItemType,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
} from '../../types'

describe('apiData utils', () => {
  describe('convertKeysToCamelCase', () => {
    it('converts snake_case keys to camelCase', () => {
      const input = {
        resource_type: 'WikiPage',
        issue_count: 5,
        workflow_state: 'completed',
      }
      const result = convertKeysToCamelCase(input)
      expect(result).toEqual({
        resourceType: 'WikiPage',
        issueCount: 5,
        workflowState: 'completed',
      })
    })

    it('handles nested objects', () => {
      const input = {
        resource_scan: {
          issue_count: 3,
          workflow_state: 'completed',
        },
      }
      const result = convertKeysToCamelCase(input)
      expect(result).toEqual({
        resourceScan: {
          issueCount: 3,
          workflowState: 'completed',
        },
      })
    })

    it('handles arrays', () => {
      const input = [{resource_type: 'WikiPage'}, {resource_type: 'Assignment'}]
      const result = convertKeysToCamelCase(input)
      expect(result).toEqual([{resourceType: 'WikiPage'}, {resourceType: 'Assignment'}])
    })

    it('returns empty string for null and undefined values', () => {
      expect(convertKeysToCamelCase(null)).toBe('')
      expect(convertKeysToCamelCase(undefined)).toBe('')
    })

    it('handles primitive values', () => {
      expect(convertKeysToCamelCase('test')).toBe('test')
      expect(convertKeysToCamelCase(123)).toBe(123)
      expect(convertKeysToCamelCase(true)).toBe(true)
    })
  })

  describe('getAsContentItemType', () => {
    it('returns ContentItemType.WikiPage for ResourceType.WikiPage', () => {
      expect(getAsContentItemType(ResourceType.WikiPage)).toBe(ContentItemType.WikiPage)
    })

    it('returns ContentItemType.Assignment for ResourceType.Assignment', () => {
      expect(getAsContentItemType(ResourceType.Assignment)).toBe(ContentItemType.Assignment)
    })

    it('returns ContentItemType.Attachment for ResourceType.Attachment', () => {
      expect(getAsContentItemType(ResourceType.Attachment)).toBe(ContentItemType.Attachment)
    })

    it('returns ContentItemType.DiscussionTopic for ResourceType.DiscussionTopic', () => {
      expect(getAsContentItemType(ResourceType.DiscussionTopic)).toBe(
        ContentItemType.DiscussionTopic,
      )
    })

    it('returns ContentItemType.Announcement for ResourceType.Announcement', () => {
      expect(getAsContentItemType(ResourceType.Announcement)).toBe(ContentItemType.Announcement)
    })

    it('returns undefined when no type is provided', () => {
      expect(getAsContentItemType(undefined)).toBeUndefined()
    })
  })

  describe('getAsContentItem', () => {
    it('converts AccessibilityResourceScan to ContentItem', () => {
      const scan: AccessibilityResourceScan = {
        id: 1,
        courseId: 1,
        resourceId: 123,
        resourceType: ResourceType.WikiPage,
        resourceName: 'Test Page',
        resourceWorkflowState: ResourceWorkflowState.Published,
        resourceUpdatedAt: '2025-01-16T12:00:00Z',
        resourceUrl: '/courses/1/pages/test-page',
        workflowState: ScanWorkflowState.Completed,
        issueCount: 5,
        issues: [],
      }

      const result = getAsContentItem(scan)

      expect(result).toEqual({
        id: 123,
        type: ResourceType.WikiPage,
        title: 'Test Page',
        published: true,
        updatedAt: '2025-01-16T12:00:00Z',
        count: 5,
        url: '/courses/1/pages/test-page',
        editUrl: '/courses/1/pages/test-page/edit',
        issues: [],
        severity: expect.any(String),
      })
    })

    it('handles unpublished resources', () => {
      const scan: AccessibilityResourceScan = {
        id: 1,
        courseId: 1,
        resourceId: 123,
        resourceType: ResourceType.Assignment,
        resourceName: 'Test Assignment',
        resourceWorkflowState: ResourceWorkflowState.Unpublished,
        resourceUpdatedAt: '2025-01-16T12:00:00Z',
        resourceUrl: '/courses/1/assignments/123',
        workflowState: ScanWorkflowState.Completed,
        issueCount: 0,
        issues: [],
      }

      const result = getAsContentItem(scan)

      expect(result.published).toBe(false)
    })

    it('handles missing resourceName', () => {
      const scan: AccessibilityResourceScan = {
        id: 1,
        courseId: 1,
        resourceId: 123,
        resourceType: ResourceType.DiscussionTopic,
        resourceName: null as any,
        resourceWorkflowState: ResourceWorkflowState.Published,
        resourceUpdatedAt: '2025-01-16T12:00:00Z',
        resourceUrl: '/courses/1/discussion_topics/123',
        workflowState: ScanWorkflowState.Completed,
        issueCount: 0,
        issues: [],
      }

      const result = getAsContentItem(scan)

      expect(result.title).toBe('')
    })
  })

  describe('getAsAccessibilityResourceScan', () => {
    it('converts ContentItem to AccessibilityResourceScan', () => {
      const item: ContentItem = {
        id: 123,
        type: ResourceType.DiscussionTopic,
        title: 'Test Discussion',
        published: true,
        updatedAt: '2025-01-16T12:00:00Z',
        count: 3,
        url: '/courses/1/discussion_topics/123',
        editUrl: '/courses/1/discussion_topics/123/edit',
        issues: [],
        severity: 'Low',
      }

      const result = getAsAccessibilityResourceScan(item, 1)

      expect(result).toEqual({
        id: 123,
        courseId: 1,
        resourceId: 123,
        resourceType: ResourceType.DiscussionTopic,
        resourceName: 'Test Discussion',
        resourceWorkflowState: ResourceWorkflowState.Published,
        resourceUpdatedAt: '2025-01-16T12:00:00Z',
        resourceUrl: '/courses/1/discussion_topics/123',
        workflowState: ScanWorkflowState.Completed,
        issueCount: 3,
        issues: [],
      })
    })

    it('handles unpublished items', () => {
      const item: ContentItem = {
        id: 123,
        type: ResourceType.Assignment,
        title: 'Test Assignment',
        published: false,
        updatedAt: '2025-01-16T12:00:00Z',
        count: 0,
        url: '/courses/1/assignments/123',
        editUrl: '/courses/1/assignments/123/edit',
        issues: [],
      }

      const result = getAsAccessibilityResourceScan(item, 1)

      expect(result.resourceWorkflowState).toBe(ResourceWorkflowState.Unpublished)
    })

    it('handles missing issues array', () => {
      const item: ContentItem = {
        id: 123,
        type: ResourceType.WikiPage,
        title: 'Test Page',
        published: true,
        updatedAt: '2025-01-16T12:00:00Z',
        count: 0,
        url: '/courses/1/pages/test-page',
        editUrl: '/courses/1/pages/test-page/edit',
      }

      const result = getAsAccessibilityResourceScan(item, 1)

      expect(result.issues).toEqual([])
    })
  })
})
