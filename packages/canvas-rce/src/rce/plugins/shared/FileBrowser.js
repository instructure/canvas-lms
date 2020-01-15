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
import {func} from 'prop-types'
import {View} from '@instructure/ui-layout'

// TODO: should find a better way to share this code
import FileBrowser from '../../../../../../app/jsx/shared/rce/FileBrowser'

RceFileBrowser.propTypes = {
  onFileSelect: func.isRequired
}

export default function RceFileBrowser({onFileSelect}) {
  function handleFileSelect(fileInfo) {
    fileInfo.title = fileInfo.name
    fileInfo.href = fileInfo.api.url
    onFileSelect({
      name: fileInfo.name,
      title: fileInfo.name,
      href: fileInfo.api.url
    })
  }

  return (
    <View as="div" margin="medium" data-testid="instructure_links-FilesPanel">
      <FileBrowser allowUpload={false} selectFile={handleFileSelect} />
    </View>
  )
}
