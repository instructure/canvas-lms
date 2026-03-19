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
import {IconTrashLine, IconCheckMarkSolid, IconDocumentLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {ContextFile} from './types'
import {formatFileSize} from './fileFormatters'

const I18n = createI18nScope('canvas_file_upload')

interface FileListProps {
  files: ContextFile[]
  uploadingFileNames: Set<string>
  onRemoveFile: (fileId: string) => void
}

const FileList: React.FC<FileListProps> = ({files, uploadingFileNames, onRemoveFile}) => {
  return (
    <View as="div" margin="medium 0" borderWidth="small" borderRadius="medium">
      <View as="div" padding="small" background="secondary">
        <Text weight="bold">{I18n.t('File Name')}</Text>
      </View>
      <View as="div">
        {/* Show uploading files first */}
        {Array.from(uploadingFileNames).map(fileName => (
          <View key={`uploading-${fileName}`} as="div" padding="small" borderWidth="small 0 0 0">
            <Flex justifyItems="space-between" alignItems="center">
              <Flex.Item shouldGrow={true}>
                <Flex alignItems="center" gap="small">
                  <IconDocumentLine />
                  <View>
                    <Text weight="bold">{fileName}</Text>
                    <br />
                    <Text size="small" color="secondary">
                      {I18n.t('Uploading...')}
                    </Text>
                  </View>
                </Flex>
              </Flex.Item>
              <Flex.Item padding="0 small">
                <Spinner renderTitle={I18n.t('Uploading')} size="x-small" />
              </Flex.Item>
              <Flex.Item>
                {/* Empty space for alignment */}
                <View as="div" width="2.5rem" />
              </Flex.Item>
            </Flex>
          </View>
        ))}
        {/* Show uploaded files */}
        {files.map(file => (
          <View key={file.id} as="div" padding="small" borderWidth="small 0 0 0">
            <Flex justifyItems="space-between" alignItems="center">
              <Flex.Item shouldGrow={true}>
                <Flex alignItems="center" gap="small">
                  <IconDocumentLine />
                  <View>
                    <Text weight="bold">{file.display_name}</Text>
                    <br />
                    <Text size="small" color="secondary">
                      {formatFileSize(file.size)} • {file.content_type}
                    </Text>
                  </View>
                </Flex>
              </Flex.Item>
              <Flex.Item padding="0 small">
                <IconCheckMarkSolid color="success" />
              </Flex.Item>
              <Flex.Item>
                <IconButton
                  data-testid={`remove-file-${file.id}`}
                  screenReaderLabel={I18n.t('Remove %{fileName}', {
                    fileName: file.display_name,
                  })}
                  onClick={() => onRemoveFile(file.id)}
                  withBackground={false}
                  withBorder={false}
                  size="small"
                >
                  <IconTrashLine />
                </IconButton>
              </Flex.Item>
            </Flex>
          </View>
        ))}
      </View>
    </View>
  )
}

export default FileList
export {FileList}
