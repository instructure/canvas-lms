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

import React, {Suspense} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import formatMessage from '../../../format-message'
import {ICON_MAKER_ICONS} from '../instructure_icon_maker/svg/constants'

const thePanels = {
  icon_maker_icons: React.lazy(
    () => import('../instructure_icon_maker/components/SavedIconMakerList'),
  ),
  links: React.lazy(() => import('../instructure_links/components/LinksPanel')),
  images: React.lazy(() => import('../instructure_image/Images')),
  documents: React.lazy(() => import('../instructure_documents/components/DocumentsPanel')),
  media: React.lazy(() => import('../instructure_record/MediaPanel')),
  all: React.lazy(() => import('./RceFileBrowser')),
  unknown: React.lazy(() => import('./UnknownFileTypePanel')),
}

// Returns a Suspense wrapped lazy loaded component
// pulled from useLazy's cache
export function DynamicPanel(props: any) {
  let key = ''
  if (props.contentType === 'links') {
    key = 'links'
  } else {
    key = props.contentSubtype in thePanels ? props.contentSubtype : 'unknown'
  }
  // @ts-expect-error
  const Component = thePanels[key]
  return (
    <Suspense fallback={<Spinner renderTitle={renderLoading} size="large" />}>
      <Component {...props} />
    </Suspense>
  )
}

export const FILTER_SETTINGS_BY_PLUGIN = {
  user_documents: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  course_documents: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  group_documents: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  user_images: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  course_images: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  group_images: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  user_media: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  course_media: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  group_media: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  course_links: {
    contextType: 'course',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  course_link_edit: {
    contextType: 'course',
    contentType: 'links',
    contentSubtype: 'edit',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  group_links: {
    contextType: 'group',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  list_icon_maker_icons: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: ICON_MAKER_ICONS,
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: '',
  },
  all: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'all',
    sortValue: 'alphabetical',
    sortDir: 'asc',
    searchString: '',
  },
}

export function isLoading(sprops: {collections: any; documents: any; media: any; all_files: any}) {
  return (
    sprops.collections.announcements?.isLoading ||
    sprops.collections.assignments?.isLoading ||
    sprops.collections.discussions?.isLoading ||
    sprops.collections.modules?.isLoading ||
    sprops.collections.quizzes?.isLoading ||
    sprops.collections.wikiPages?.isLoading ||
    sprops.documents.course?.isLoading ||
    sprops.documents.user?.isLoading ||
    sprops.documents.group?.isLoading ||
    sprops.media.course?.isLoading ||
    sprops.media.user?.isLoading ||
    sprops.media.group?.isLoading ||
    sprops.all_files?.isLoading
  )
}

function renderLoading() {
  return formatMessage('Loading')
}

export const UploadCanvasPanelIds = [
  'user_documents',
  'course_documents',
  'group_documents',
  'user_images',
  'course_images',
  'group_images',
  'user_media',
  'course_media',
  'group_media',
  'course_links',
  'group_links',
  'list_icon_maker_icons',
  'all',
] as const

export const CanvasPanelTitles = {
  user_documents: formatMessage('User Documents'),
  course_documents: formatMessage('Course Documents'),
  group_documents: formatMessage('Group Documents'),
  user_images: formatMessage('User Images'),
  course_images: formatMessage('Course Images'),
  group_images: formatMessage('Group Images'),
  user_media: formatMessage('User Media'),
  course_media: formatMessage('Course Media'),
  group_media: formatMessage('Group Media'),
  course_links: formatMessage('Course Links'),
  group_links: formatMessage('Group Links'),
  list_icon_maker_icons: formatMessage('Icon Maker Icons'),
  all: formatMessage('All'),
} as const
