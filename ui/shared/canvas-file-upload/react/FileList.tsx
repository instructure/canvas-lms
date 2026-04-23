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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconWarningSolid, IconXSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {ContextFile} from './types'
import ContextFilePill from './ContextFilePill'

const I18n = createI18nScope('canvas_file_upload')

interface FileListProps {
  files: ContextFile[]
  uploadingFileNames: Set<string>
  failedFileNames: Set<string>
  onRemoveFile?: (fileId: string) => void
  onClearFailedFile?: (name: string) => void
}

const FileList: React.FC<FileListProps> = ({
  files,
  uploadingFileNames,
  failedFileNames,
  onRemoveFile,
  onClearFailedFile,
}) => {
  return (
    <Flex as="div" wrap="wrap" gap="x-small" margin="small 0">
      {Array.from(uploadingFileNames).map(fileName => (
        <Flex.Item key={`uploading-${fileName}`}>
          <View
            as="div"
            borderWidth="small"
            borderRadius="large"
            padding="x-small small"
            background="primary"
          >
            <Flex alignItems="center" gap="x-small">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Uploading')} size="x-small" />
              </Flex.Item>
              <Flex.Item>
                <Text size="small">{I18n.t('%{name} uploading', {name: fileName})}</Text>
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>
      ))}

      {Array.from(failedFileNames).map(fileName => (
        <Flex.Item key={`failed-${fileName}`}>
          <View
            as="div"
            borderWidth="small"
            borderRadius="large"
            padding="x-small small"
            background="primary"
          >
            <Flex alignItems="center" gap="x-small">
              <Flex.Item>
                <IconWarningSolid color="warning" size="x-small" />
              </Flex.Item>
              <Flex.Item>
                <Text size="small">{I18n.t('%{name} failed', {name: fileName})}</Text>
              </Flex.Item>
              {onClearFailedFile && (
                <Flex.Item>
                  <IconButton
                    data-testid={`dismiss-failed-${fileName}`}
                    screenReaderLabel={I18n.t('Dismiss %{name}', {name: fileName})}
                    onClick={() => onClearFailedFile(fileName)}
                    withBackground={false}
                    withBorder={false}
                    size="small"
                  >
                    <IconXSolid />
                  </IconButton>
                </Flex.Item>
              )}
            </Flex>
          </View>
        </Flex.Item>
      ))}

      {files.map(file => (
        <Flex.Item key={file.id}>
          <ContextFilePill file={file} onRemove={onRemoveFile} />
        </Flex.Item>
      ))}
    </Flex>
  )
}

export default FileList
export {FileList}
