/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {func, shape, string} from 'prop-types';

import {BTN_AND_ICON_ATTRIBUTE} from '../../instructure_buttons/registerEditToolbar'
import Images from '../../instructure_image/Images'

export function rceToFile({createdAt, id, name, thumbnailUrl, type, url}) {
  return {
    content_type: type,
    date: createdAt,
    display_name: name,
    filename: name,
    href: url,
    id,
    thumbnail_url: thumbnailUrl,
    [BTN_AND_ICON_ATTRIBUTE]: true
  }
}

const SavedButtonList = ({context, onImageEmbed, searchString, sortBy, source}) => {
  const [buttonsAndIconsBookmark, setButtonsAndIconsBookmark] = useState(null)
  const [buttonsAndIcons, setButtonsAndIcons] = useState([])
  const [hasMore, setHasMore] = useState(true)
  const [isLoading, setIsLoading] = useState(true)

  const resetState = () => {
    setButtonsAndIconsBookmark(null)
    setButtonsAndIcons([])
    setHasMore(true)
    setIsLoading(true)
  }

  const onLoadedImages = ({bookmark, files}) => {
    setButtonsAndIconsBookmark(bookmark)
    setHasMore(bookmark !== null)
    setIsLoading(false)

    setButtonsAndIcons(prevButtonsAndIcons => [
      ...prevButtonsAndIcons,
      ...files
        .filter(({type}) => type === 'image/svg+xml')
        .map(rceToFile)
    ])
  }

  const fetchButtonsAndIcons = bookmark => {
    setIsLoading(true)
    source.fetchButtonsAndIcons(
      {contextId: context.id, contextType: context.type},
      bookmark,
      searchString,
      sortBy,
      onLoadedImages
    )
  }

  useEffect(() => {
    resetState()
  }, [searchString, sortBy.order, sortBy.sort])

  return (
    <Images
      contextType={context.type}
      fetchInitialImages={() => {
        fetchButtonsAndIcons()
      }}
      fetchNextImages={() => {
        fetchButtonsAndIcons(buttonsAndIconsBookmark)
      }}
      images={{[context.type]: {error: null, files: buttonsAndIcons, hasMore, isLoading}}}
      onImageEmbed={onImageEmbed}
      searchString={searchString}
      sortBy={sortBy}
    />
  )
}

SavedButtonList.propTypes = {
  context: shape({
    id: string.isRequired,
    type: string.isRequired,
  }),
  onImageEmbed: func.isRequired,
  searchString: string,
  sortBy: shape({
    order: string,
    sort: string
  }),
  source: shape({
    fetchButtonsAndIcons: func.isRequired
  })
}

export default SavedButtonList
