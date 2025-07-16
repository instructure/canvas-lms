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

import {ContentItem, ContentItemType} from '../types'

export const sampleTableData: ContentItem[] = [
  {
    id: 1,
    title: 'Test Wiki Page 1',
    type: ContentItemType.WikiPage,
    published: true,
    updatedAt: '2025-06-03T00:00:00Z',
    count: 0,
    url: '/wiki_page_1',
    issues: [],
  },
  {
    id: 2,
    title: 'Test Assignment 1',
    type: ContentItemType.Assignment,
    published: true,
    updatedAt: '2025-06-04T00:00:00Z',
    count: 0,
    url: '/assignment_1',
    issues: [],
  },
  {
    id: 3,
    title: 'Test Assignment 2',
    type: ContentItemType.Assignment,
    published: false,
    updatedAt: '2025-06-08T00:00:00Z',
    count: 0,
    url: '/assignment_2',
    issues: [],
  },
]
