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

import React, {useMemo} from 'react'
import {func, object, string} from 'prop-types'
import classnames from 'classnames'
import {View} from '@instructure/ui-view'
import {downloadToWrap} from '../../../common/fileUrl'
import {mediaPlayerURLFromFile} from './fileTypeUtils'
import RceApiSource from '../../../rcs/api'
import addIconMakerAttributes from '../instructure_icon_maker/utils/addIconMakerAttributes'

// TODO: should find a better way to share this code
import FileBrowser from '../../../canvasFileBrowser/FileBrowser'
import {isPreviewable} from './Previewable'

RceFileBrowser.propTypes = {
  onFileSelect: func.isRequired,
  onAllFilesLoading: func.isRequired,
  searchString: string.isRequired,
  canvasOrigin: string,
  jwt: string.isRequired,
  refreshToken: func,
  host: string.isRequired,
  source: object,
  context: object.isRequired,
}

export default function RceFileBrowser(props) {
  const {
    onFileSelect,
    searchString,
    onAllFilesLoading,
    jwt,
    refreshToken,
    host,
    source,
    canvasOrigin,
  } = props

  const apiSource = useMemo(() => {
    return (
      source ||
      new RceApiSource({
        jwt,
        refreshToken,
        host,
        canvasOrigin,
      })
    )
  }, [host, jwt, refreshToken, source, canvasOrigin])

  function handleFileSelect(fileInfo) {
    const content_type = fileInfo.api.type
    const canPreview = isPreviewable(content_type)

    const url = downloadToWrap(fileInfo.src)
    const embedded_iframe_url = mediaPlayerURLFromFile(fileInfo.api)

    let onFileSelectParams = {
      name: fileInfo.name,
      title: fileInfo.name,
      href: url,
      embedded_iframe_url,
      media_id: fileInfo.api.embed?.id || fileInfo.api.mediaEntryId,
      target: '_blank',
      content_type,
    }
    if (fileInfo.api?.category === 'icon_maker_icons') {
      onFileSelectParams.src = fileInfo.api.url
      addIconMakerAttributes(onFileSelectParams)
    } else {
      // do not add this to icon maker icons
      const clazz = classnames('instructure_file_link', {
        instructure_scribd_file: canPreview,
        inline_disabled: true,
      })
      onFileSelectParams = {...onFileSelectParams, class: clazz}
    }

    onFileSelect(onFileSelectParams)
  }

  return (
    <View as="div" margin="medium" data-testid="instructure_links-FilesPanel">
      <FileBrowser
        selectFile={handleFileSelect}
        contentTypes={['**']}
        searchString={searchString}
        onLoading={onAllFilesLoading}
        source={apiSource}
        context={props.context}
      />
    </View>
  )
}
