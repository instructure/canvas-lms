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

import React, {useEffect, useState} from 'react'
import {arrayOf, bool, func, objectOf, shape, string} from 'prop-types'
import classnames from 'classnames'
import {View} from '@instructure/ui-layout'
import {mediaObjectShape} from './fileShape'
import {downloadToWrap} from '../../../common/fileUrl'
import {embedded_iframe_url_fromFile} from './fileTypeUtils'

// TODO: should find a better way to share this code
import FileBrowser from '../../../canvasFileBrowser/FileBrowser'
import {isPreviewable} from './Previewable'

RceFileBrowser.propTypes = {
  onFileSelect: func.isRequired,
  fetchInitialMedia: func.isRequired,
  fetchNextMedia: func.isRequired,
  media: objectOf(
    shape({
      files: arrayOf(shape(mediaObjectShape)).isRequired,
      bookmark: string,
      hasMore: bool,
      isLoading: bool,
      error: string
    })
  ).isRequired
}

export default function RceFileBrowser(props) {
  const {onFileSelect, fetchInitialMedia, fetchNextMedia} = props
  const media = props.media.user
  const {hasMore, isLoading, files} = media
  const [fetchedInitial, setFetchedInitial] = useState(false)

  useEffect(() => {
    if (!fetchedInitial) {
      fetchInitialMedia({order: 'asc', sort: 'alphabetical'})
      setFetchedInitial(true)
    } else if (hasMore && !isLoading) {
      fetchNextMedia({order: 'asc', sort: 'alphabeetical'})
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasMore, isLoading, fetchedInitial])

  function handleFileSelect(fileInfo) {
    const content_type = fileInfo.api['content-type']
    const canPreview = isPreviewable(content_type)
    const clazz = classnames('instructure_file_link', {
      instructure_scribd_file: canPreview
    })
    const url = downloadToWrap(fileInfo.api.url)
    const embedded_iframe_url = embedded_iframe_url_fromFile(fileInfo.api)

    onFileSelect({
      name: fileInfo.name,
      title: fileInfo.name,
      href: url,
      embedded_iframe_url,
      target: '_blank',
      class: clazz,
      content_type
    })
  }

  return (
    <View as="div" margin="medium" data-testid="instructure_links-FilesPanel">
      <FileBrowser
        allowUpload={false}
        selectFile={handleFileSelect}
        mediaFiles={files}
        contentTypes={['**']}
      />
    </View>
  )
}
