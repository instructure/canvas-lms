/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export type Card = {
  shortName: string
  originalName: string
  courseCode: string
  id: string
  href: string
  links: any
  term: string | null
  assetString: string
  color: string
  image: string
  isFavorited: boolean
  enrollmentType: string
  enrollmentState: string
  observee: string | null
  position: number
  published: boolean
  canChangeCoursePublishState: boolean
  defaultView: string
  pagesUrl: string
  frontPageTitle: string
  isK5Subject: boolean
  isHomeroom: boolean
}

export type ActivityStreamSummary = {
  id: string
  summary: StreamSummaryItem[]
}

export type StreamSummaryItem = {
  count: number
  notification_category: string | null
  type: string
  unread_count: number
}
