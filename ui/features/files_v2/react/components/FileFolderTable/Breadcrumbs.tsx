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

import React from 'react'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Folder} from '../../../interfaces/File'
import {useScope as createI18nScope} from '@canvas/i18n'
import {generateUrlPath} from '../../../utils/folderUtils'
import {getFilesEnv} from '../../../utils/filesEnvUtils'
import {Link as RouterLink} from 'react-router-dom'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconArrowOpenStartLine} from '@instructure/ui-icons'
import {useFileManagement} from '../../contexts/FileManagementContext'

type BreadcrumData = {
  id: string
  name: string
  url: string
}

type BreadcrumbsProps = {
  items: BreadcrumData[]
}

type ResponsiveBreadcrumbsProps = {
  folders: Folder[]
  size: 'small' | 'medium' | 'large'
  search?: string | null
}

const I18n = createI18nScope('files_v2')

const SmallBreadcrumbs = ({items}: BreadcrumbsProps) => {
  const isOnlyCrumb = items.length === 1
  if (isOnlyCrumb) {
    const breadcrumb = items[0]
    return (
      <Text weight="bold">
        <TruncateText>{breadcrumb.name}</TruncateText>
      </Text>
    )
  } else {
    const breadcrumb = items[items.length - 2]
    return (
      <Link
        as={RouterLink}
        to={breadcrumb.url}
        isWithinText={false}
        renderIcon={IconArrowOpenStartLine}
      >
        <TruncateText>{breadcrumb.name}</TruncateText>
      </Link>
    )
  }
}

const LargeBreadcrumbs = ({items}: BreadcrumbsProps) => {
  const isOnlyCrumb = items.length === 1
  return (
    <Breadcrumb label={I18n.t('You are here:')}>
      {items.map((item, index) => {
        const isLastCrumb = index === items.length - 1
        if (isOnlyCrumb) {
          return (
            <Breadcrumb.Link key={item.id}>
              <b>{item.name}</b>
            </Breadcrumb.Link>
          )
        } else if (isLastCrumb) {
          return <Breadcrumb.Link key={item.id}>{item.name}</Breadcrumb.Link>
        } else {
          return (
            <Breadcrumb.Link key={item.id} as={RouterLink} to={item.url}>
              {item.name}
            </Breadcrumb.Link>
          )
        }
      })}
    </Breadcrumb>
  )
}

const ResponsiveBreadcrumbs = ({folders, size, search}: ResponsiveBreadcrumbsProps) => {
  const {contextType, contextId, showingAllContexts} = useFileManagement()

  const breadcrumbs = folders.map((folder, index) => {
    const folderContextType = (folder.context_type || '').toLowerCase()
    const folderContextId = (folder.context_id || -1).toString()
    const isContextRoot = folderContextType === contextType && folderContextId === contextId
    const isRootCrumb = index === 0 && isContextRoot

    let name
    if (!folder.parent_folder_id) {
      const context = getFilesEnv().contextFor({
        contextType: folderContextType,
        contextId: folderContextId,
      })
      name = context?.name
    }
    name ||= folder.custom_name || folder.name

    const url = isRootCrumb && !showingAllContexts ? '/' : generateUrlPath(folder)
    return {id: folder.id.toString(), name, url}
  })

  if (search) {
    breadcrumbs.push({
      id: 'search',
      name: I18n.t('Search results for "%{search}"', {search}),
      url: '',
    })
  }

  if (showingAllContexts) {
    breadcrumbs.unshift({id: 'all-my-files', name: I18n.t('All My Files'), url: '/'})
  }

  if (size === 'small') {
    return <SmallBreadcrumbs items={breadcrumbs} />
  } else {
    return <LargeBreadcrumbs items={breadcrumbs} />
  }
}

export default ResponsiveBreadcrumbs
