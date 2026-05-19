/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {trackPendoEvent} from '@instructure/canvas-media'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {func, oneOf, shape, string} from 'prop-types'
import React, {useRef} from 'react'
import {
  LoadingIndicator,
  LoadingStatus,
  LoadMoreButton,
  useIncrementalLoading,
} from '../../../../common/incremental-loading'
import formatMessage from '../../../../format-message'
import RCEGlobals from '../../../RCEGlobals'
import Link from '../../instructure_documents/components/Link'
import {contentTrayDocumentShape} from '../../shared/fileShape'

const PENDING_MEDIA_ENTRY_ID = 'maybe'

function hasFiles(media) {
  return media.files.length > 0
}

function isEmpty(media) {
  return !hasFiles(media) && !media.hasMore && !media.isLoading
}

function renderLinks(files, handleClick, lastItemRef) {
  return files.map((f, index) => {
    let focusRef = null
    if (index === files.length - 1) {
      focusRef = lastItemRef
    }
    return (
      <Link
        key={f.id}
        {...f}
        onClick={handleClick}
        focusRef={focusRef}
        disabled={f.media_entry_id === PENDING_MEDIA_ENTRY_ID}
        disabledMessage={formatMessage('Media file is processing. Please try again later.')}
      />
    )
  })
}

function renderLoadingError(_error) {
  return (
    <View as="div" role="alert" margin="medium">
      <Text color="danger">{formatMessage('Loading failed.')}</Text>
    </View>
  )
}

export default function MediaPanel(props) {
  const {fetchInitialMedia, fetchNextMedia, contextType, sortBy, searchString} = props
  const media = props.media[contextType]
  const {hasMore, isLoading, error, files} = media
  const lastItemRef = useRef(null)

  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,
    onLoadInitial: fetchInitialMedia,
    onLoadMore: fetchNextMedia,
    records: files,
    contextType,
    sortBy,
    searchString,
  })

  const handleFileClick = file => {
    if (RCEGlobals.getFeatures()?.rce_asr_captioning_improvements) {
      const contentType = file.content_type || file['content-type'] || ''
      trackPendoEvent('canvas_native_media_embedded', {
        insertion_method: 'select_existing',
        media_id: file.id,
        media_kind: contentType.startsWith('audio/') ? 'audio' : 'video',
        resourceType: props.contextType,
      })
    }
    props.onMediaEmbed(file)
  }

  return (
    <View as="div" data-testid="instructure_links-MediaPanel">
      {renderLinks(files, handleFileClick, lastItemRef)}

      {loader.isLoading && <LoadingIndicator loader={loader} />}

      {!loader.isLoading && loader.hasMore && <LoadMoreButton loader={loader} />}

      <LoadingStatus loader={loader} />

      {error && renderLoadingError(error)}

      {isEmpty(media) && (
        <View as="div" role="alert" padding="medium">
          {formatMessage('No results.')}
        </View>
      )}
    </View>
  )
}

MediaPanel.propTypes = {
  contextType: string.isRequired,
  fetchInitialMedia: func.isRequired,
  fetchNextMedia: func.isRequired,
  onMediaEmbed: func.isRequired,
  media: contentTrayDocumentShape.isRequired,
  sortBy: shape({
    sort: oneOf(['date_added', 'alphabetical']).isRequired,
    order: oneOf(['asc', 'desc']).isRequired,
  }),
  searchString: string,
}
