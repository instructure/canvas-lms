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

import {IssueRuleType} from '../types'
import {getIssueGrouping} from '../utils/issueGrouping'
import {usePendoTracking} from './usePendoTracking'

const EVENT_PREFIX = 'canvasCourseA11yChecker'

export type A11yIssueEvent = 'IssueSkipped' | 'IssueFixed' | 'PageViewOpened' | 'PageEditorOpened'
export type A11yEvent = 'CourseScanned' | 'ResourceRemediated' | 'CourseRemediated'

export const useA11yTracking = () => {
  const {trackEvent} = usePendoTracking()

  const trackA11yIssueEvent = (eventName: A11yIssueEvent, resourceType: string, ruleId: string) => {
    const {groupLabel, ruleLabel} = getIssueGrouping(ruleId as IssueRuleType)

    const prefixedEventName = `${EVENT_PREFIX}${eventName}`
    trackEvent({
      eventName: prefixedEventName,
      props: {
        primaryIssue: groupLabel,
        secondaryIssue: ruleLabel,
        resourceType: resourceType,
      },
    })
  }

  const trackA11yEvent = (eventName: A11yEvent, props?: Record<string, any>) => {
    const prefixedEventName = `${EVENT_PREFIX}${eventName}`

    trackEvent({
      eventName: prefixedEventName,
      props,
    })
  }

  return {trackA11yIssueEvent, trackA11yEvent}
}
