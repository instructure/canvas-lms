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

import React from 'react'
import {func, string} from 'prop-types'
import classnames from 'classnames'
import {View} from '@instructure/ui-view'
import {downloadToWrap} from '../../../common/fileUrl'
import {mediaPlayerURLFromFile} from './fileTypeUtils'

// TODO: should find a better way to share this code
import FileBrowser from '../../../canvasFileBrowser/FileBrowser'
import {isPreviewable} from './Previewable'

RceFileBrowser.propTypes = {
  onFileSelect: func.isRequired,
  onAllFilesLoading: func.isRequired,
  searchString: string.isRequired
}

export default function RceFileBrowser(props) {
  const {onFileSelect, searchString, onAllFilesLoading} = props

  function handleFileSelect(fileInfo) {
    const content_type = fileInfo.api['content-type']
    const canPreview = isPreviewable(content_type)
    const clazz = classnames('instructure_file_link', {
      instructure_scribd_file: canPreview
    })
    const url = downloadToWrap(fileInfo.src)
    const embedded_iframe_url = mediaPlayerURLFromFile(fileInfo.api)

    onFileSelect({
      name: fileInfo.name,
      title: fileInfo.name,
      href: url,
      embedded_iframe_url,
      media_id: fileInfo.api.media_entry_id,
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
        contentTypes={['**']}
        searchString={searchString}
        onLoading={onAllFilesLoading}
      />
    </View>
  )
}
