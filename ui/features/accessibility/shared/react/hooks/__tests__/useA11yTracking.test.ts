/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks'
import {useA11yTracking} from '../useA11yTracking'
import {usePendoTracking} from '../usePendoTracking'
import {ResourceType} from '../../types'

const mockTrackEvent = vi.fn()

vi.mock('../usePendoTracking', () => ({
  usePendoTracking: vi.fn(),
}))

describe('useA11yTracking', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(usePendoTracking).mockReturnValue({
      trackEvent: mockTrackEvent,
    })
  })

  describe('trackA11yIssueEvent', () => {
    it('tracks IssueSkipped event with correct data', () => {
      const {result} = renderHook(() => useA11yTracking())

      result.current.trackA11yIssueEvent('IssueSkipped', ResourceType.WikiPage, 'adjacent-links')

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerIssueSkipped',
        props: {
          primaryIssue: 'Links',
          secondaryIssue: 'Adjacent',
          resourceType: ResourceType.WikiPage,
        },
      })
    })

    it('tracks IssueFixed event with correct data', () => {
      const {result} = renderHook(() => useA11yTracking())

      result.current.trackA11yIssueEvent('IssueFixed', ResourceType.WikiPage, 'img-alt')

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerIssueFixed',
        props: {
          primaryIssue: 'Alt text',
          secondaryIssue: 'Missing',
          resourceType: ResourceType.WikiPage,
        },
      })
    })

    it('tracks PageViewOpened event with correct data', () => {
      const {result} = renderHook(() => useA11yTracking())

      result.current.trackA11yIssueEvent('PageViewOpened', ResourceType.Assignment, 'table-caption')

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerPageViewOpened',
        props: {
          primaryIssue: 'Table',
          secondaryIssue: 'Missing caption',
          resourceType: ResourceType.Assignment,
        },
      })
    })

    it('tracks PageEditorOpened event with correct data', () => {
      const {result} = renderHook(() => useA11yTracking())

      result.current.trackA11yIssueEvent(
        'PageEditorOpened',
        ResourceType.DiscussionTopic,
        'headings-sequence',
      )

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerPageEditorOpened',
        props: {
          primaryIssue: 'Headings',
          secondaryIssue: 'Skipped level',
          resourceType: ResourceType.DiscussionTopic,
        },
      })
    })
  })

  describe('trackA11yEvent', () => {
    it('tracks CourseScanned event without props', () => {
      const {result} = renderHook(() => useA11yTracking())

      result.current.trackA11yEvent('CourseScanned')

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerCourseScanned',
        props: undefined,
      })
    })

    it('tracks ResourceRemediated event with props', () => {
      const {result} = renderHook(() => useA11yTracking())

      result.current.trackA11yEvent('ResourceRemediated', {
        resourceType: ResourceType.WikiPage,
        issueCount: 3,
      })

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerResourceRemediated',
        props: {
          resourceType: ResourceType.WikiPage,
          issueCount: 3,
        },
      })
    })

    it('tracks CourseRemediated event with props', () => {
      const {result} = renderHook(() => useA11yTracking())
      const props = {
        activeResources: 10,
        remediatedResources: 8,
      }

      result.current.trackA11yEvent('CourseRemediated', props)

      expect(mockTrackEvent).toHaveBeenCalledWith({
        eventName: 'canvasCourseA11yCheckerCourseRemediated',
        props,
      })
    })
  })
})
