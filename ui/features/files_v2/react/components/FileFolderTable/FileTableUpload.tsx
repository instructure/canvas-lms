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
import classnames from 'classnames'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {FileDrop} from '@instructure/ui-file-drop'
import '@canvas/rails-flash-notifications'
import {BBFolderWrapper} from 'features/files_v2/utils/fileFolderWrappers'
import {RocketSVG} from '@instructure/canvas-media'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('upload_drop_zone')

interface FileTableUploadProps {
  currentFolder: BBFolderWrapper
  isDragging: boolean
  handleDrop: (
    accepted: ArrayLike<DataTransferItem | File>,
    rejected: ArrayLike<DataTransferItem | File>,
    e: React.DragEvent<Element>,
  ) => void
}

const FileTableUpload = ({currentFolder, isDragging, handleDrop}: FileTableUploadProps) => {
  const isEmptyFolder = currentFolder?.folders.length === 0 && currentFolder?.files.length === 0

  const classes = classnames({
    FileDrag: true,
    FileDrag__full: isEmptyFolder && !isDragging,
    FileDrag__dragging: isDragging,
  })

  return (
    <div data-testid="file-upload" className={classes}>
      <FileDrop
        height="max(100%, 300px)"
        shouldAllowMultiple={true}
        // Called when dropping files or when clicking,
        // after the file dialog window exits successfully
        onDrop={handleDrop}
        renderLabel={
          <Flex direction="column" height="100%" alignItems="center" justifyItems="center">
            <Billboard
              size="small"
              hero={<RocketSVG width="3em" height="3em" />}
              as="div"
              headingAs="span"
              headingLevel="h2"
              heading={I18n.t('Drop files here to upload')}
              message={isEmptyFolder && <Text color="brand">{I18n.t('or choose files')}</Text>}
            />
          </Flex>
        }
      />
    </div>
  )
}

export default FileTableUpload
