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

import React, {useState} from 'react'

import {Flex} from '@instructure/ui-flex'

import ErrorBoundary from '../ErrorBoundary'
import {useFilterSettings} from '../useFilterSettings'
import PanelFilter from './PanelFilter'
import {FILTER_SETTINGS_BY_PLUGIN, DynamicPanel} from '../canvasContentUtils'
import {useStoreProps} from '../StoreContext'

interface CanvasContentPanelProps {
  trayProps: trayProps
  canvasOrigin: string
  plugin: keyof typeof FILTER_SETTINGS_BY_PLUGIN
  setFileUrl: (url: string) => void
}

// TODO: Component is only validated for images, need to validate for other content types
export default function CanvasContentPanel({
  trayProps,
  canvasOrigin,
  plugin,
  setFileUrl,
}: CanvasContentPanelProps) {
  const [filterSettings, setFilterSettings] = useFilterSettings(FILTER_SETTINGS_BY_PLUGIN[plugin])
  const [link, setLink] = useState(null)
  const [hasLoaded, setHasLoaded] = useState(false)

  // storeProps has functions that collide with what we want to do in a block editor setting
  const baseStoreProps = useStoreProps()
  const {onImageEmbed: _, onMediaEmbed: _m, ...storeProps} = baseStoreProps

  function handleFilterChange(
    newFilter: any,
    onChangeContext: (arg0: {contextType: any; contextId: any}) => void,
    onChangeSearchString: (arg0: any) => void,
    onChangeSortBy: (arg0: {sort: any; dir: any}) => void,
  ) {
    const newFilterSettings = {...newFilter}
    if (newFilterSettings.sortValue) {
      newFilterSettings.sortDir = newFilterSettings.sortValue === 'alphabetical' ? 'asc' : 'desc'
      onChangeSortBy({sort: newFilterSettings.sortValue, dir: newFilterSettings.sortDir})
    }

    if (
      'searchString' in newFilterSettings &&
      filterSettings.searchString !== newFilterSettings.searchString
    ) {
      onChangeSearchString(newFilterSettings.searchString)
    }

    setFilterSettings(newFilterSettings)
    if (newFilterSettings.contentType) {
      let contextType, contextId
      switch (newFilterSettings.contentType) {
        case 'user_files':
          contextType = 'user'
          contextId = trayProps.containingContext.userId
          break
        case 'group_files':
          contextType = 'group'
          contextId = trayProps.containingContext.contextId
          break
        case 'course_files':
          contextType = trayProps.contextType
          contextId = trayProps.containingContext.contextId
          break
        case 'links':
          contextType = trayProps.containingContext.contextType
          contextId = trayProps.containingContext.contextId
      }
      onChangeContext({contextType, contextId})
      // context is only changed on load
      setHasLoaded(true)
    }
  }

  const handleImageClick = (image: {href: string}) => {
    setFileUrl(image.href)
  }

  const handleMediaClick = (media: {id: string}) => {
    setFileUrl(`/media_attachments_iframe/${media.id}`)
  }

  return (
    <Flex as="div" direction="column" tabIndex={-1}>
      <Flex.Item padding="medium">
        <PanelFilter
          {...filterSettings}
          onChange={(newFilter: any) => {
            handleFilterChange(
              newFilter,
              storeProps.onChangeContext,
              storeProps.onChangeSearchString,
              storeProps.onChangeSortBy,
            )
          }}
        />
      </Flex.Item>
      <Flex.Item shouldGrow={true} shouldShrink={true} margin="xx-small xxx-small 0">
        {hasLoaded && (
          <Flex justifyItems="space-between" direction="column" height="100%">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <ErrorBoundary>
                <DynamicPanel
                  contentType={filterSettings.contentType}
                  contentSubtype={filterSettings.contentSubtype}
                  sortBy={{sort: filterSettings.sortValue, order: filterSettings.sortDir}}
                  searchString={filterSettings.searchString}
                  canvasOrigin={canvasOrigin}
                  context={{type: trayProps.contextType, id: trayProps.contextId}}
                  editing={false}
                  onEditClick={setLink}
                  selectedLink={link}
                  onImageEmbed={handleImageClick}
                  onMediaEmbed={handleMediaClick}
                  {...storeProps}
                />
              </ErrorBoundary>
            </Flex.Item>
          </Flex>
        )}
      </Flex.Item>
    </Flex>
  )
}

type trayProps = {
  canUploadFiles: boolean
  contextId: string // initial value indicating the user's context (e.g. student v teacher), not the tray's
  contextType: string // initial value indicating the user's context, not the tray's
  containingContext: {
    contextType: string
    contextId: string
    userId: string
  }
  filesTabDisabled: boolean
  host: string
  jwt: string
  refreshToken: Function
  source: {
    fetchImages: Function
  }
  themeUrl: string
  storeProps: any
}
