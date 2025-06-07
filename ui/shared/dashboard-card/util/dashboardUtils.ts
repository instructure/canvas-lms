/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
// @ts-expect-error
import type {Card, ActivityStreamSummary} from './types'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

interface HasPosition {
  position: number | undefined
}

export function sortByPosition(a: HasPosition, b: HasPosition) {
  const positionA = a.position !== undefined ? a.position : Infinity
  const positionB = b.position !== undefined ? b.position : Infinity
  if (positionA === positionB) return 0
  return positionA - positionB
}

export function mapDashboardResponseToCard(data: any): Card[] {
  // Handle GraphQL response structure
  const nodes = data?.legacyNode?.favoriteCoursesConnection?.nodes
  if (nodes && Array.isArray(nodes)) {
    return nodes
      .map((node: any) => {
        const course_id = node._id
        const card = node.dashboardCard
        if (!card) {
          return null
        }
        return {
          shortName: card.shortName,
          originalName: card.originalName,
          courseCode: card.courseCode,
          id: course_id,
          href: card.href,
          links: card.links,
          term: card.term.name !== 'Default Term' ? card.term.name : null,
          assetString: card.assetString,
          color: card.color,
          image: card.image,
          isFavorited: card.isFavorited,
          enrollmentType: card.enrollmentType,
          enrollmentState: card.enrollmentState,
          observee: card.observee,
          position: card.position,
          published: card.published,
          canChangeCoursePublishState: card.canChangeCoursePublishState,
          defaultView: card.defaultView,
          pagesUrl: card.pagesUrl,
          frontPageTitle: card.frontPageTitle,
          isK5Subject: card.isK5Subject,
          isHomeroom: card.isHomeroom,
          canReadAnnouncements: card.canReadAnnouncements,
          canManage: card.canManage,
          longName: card.longName,
        }
      })
      .filter((card: any) => card !== null)
  }

  // Handle REST API response structure (array of cards)
  if (Array.isArray(data)) {
    return data
  }

  return []
}

// This is used as a selector in the useFetchDashboardCards hook
export function processDashboardCards(data: any): Card[] {
  // If data is already an array (REST API response), return it directly
  if (Array.isArray(data)) {
    return data.sort(sortByPosition)
  }

  // Otherwise, try to map GraphQL response
  const mapped = mapDashboardResponseToCard(data)
  return mapped.sort(sortByPosition)
}

const dashboard_I18n = createI18nScope('load_card_dashboard')

export const handleDashboardCardError = (e: Error) => {
  showFlashAlert({message: dashboard_I18n.t('Failed loading course cards'), err: e, type: 'error'})
}

export function mapActivityStreamSummaries(data: any): ActivityStreamSummary[] {
  return (
    data?.legacyNode?.favoriteCoursesConnection?.nodes.map((node: any) => {
      const activityStream = node?.activityStream
      return {
        id: node._id,
        summary: activityStream
          ? activityStream.summary.map((item: any) => ({
              count: item.count,
              notification_category: item.notificationCategory,
              type: item.type,
              unread_count: item.unreadCount,
            }))
          : [],
      }
    }) || []
  )
}
