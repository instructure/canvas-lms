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
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {CloseButton} from '@instructure/ui-buttons'
import {type File} from '../../../interfaces/File'
import {useScope as createI18nScope} from '@canvas/i18n'
import {formatFileSize} from '@canvas/util/fileHelper'
import {getRestrictedText, isPublished, isRestricted, isHidden} from '../../../utils/fileUtils'

const I18n = createI18nScope('files_v2')

interface FilePreviewTrayProps {
  onDismiss: () => void
  item: File
}

const FilePreviewTray = ({onDismiss, item}: FilePreviewTrayProps) => {
  const name = item.display_name
  const published = isPublished(item)
  const restricted = isRestricted(item)
  const hidden = isHidden(item)

  const renderCloseButton = () => {
    return (
      <Flex>
        <Flex.Item shouldGrow shouldShrink>
          <Heading>{I18n.t('File Info')}</Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            onClick={onDismiss}
            color="primary-inverse"
            data-testid="tray-close-button"
          />
        </Flex.Item>
      </Flex>
    )
  }

  const statusText = () => {
    if (published && restricted) return getRestrictedText(item)
    if (published && hidden) return I18n.t('Hidden')
    return published ? I18n.t('Published') : I18n.t('Unpublished')
  }

  return (
    <Flex alignItems="center" justifyItems="center" padding="none" gap="none" height="100%">
      <Flex.Item padding="none" margin="none" height="100%">
        <View as="div" padding="medium" background="primary-inverse" height="100%">
          <Flex direction="column" gap="small">
            <Flex.Item>{renderCloseButton()}</Flex.Item>
            <Flex.Item>
              <Text weight="bold">{I18n.t('Name')}</Text>
              <br />
              <Text>{name}</Text>
            </Flex.Item>
            {'locked' in item && (
              <Flex.Item>
                <Text weight="bold">{I18n.t('Status')}</Text>
                <br />
                <Text>{statusText()}</Text>
              </Flex.Item>
            )}
            {'usage_rights' in item && item.usage_rights && (
              <Flex.Item>
                <Text weight="bold">{I18n.t('License')}</Text>
                <br />
                <Text>{item.usage_rights.license_name}</Text>
              </Flex.Item>
            )}
            {'content-type' in item && (
              <Flex.Item>
                <Text weight="bold">{I18n.t('Type')}</Text>
                <br />
                <Text>{item['content-type']}</Text>
              </Flex.Item>
            )}
            {'size' in item && (
              <Flex.Item>
                <Text weight="bold">{I18n.t('Size')}</Text>
                <br />
                <Text>{formatFileSize(item.size)}</Text>
              </Flex.Item>
            )}
            {'created_at' in item && (
              <Flex.Item>
                <Text weight="bold">{I18n.t('Date Created')}</Text>
                <br />
                <Text>{new Date(item.created_at).toLocaleString()}</Text>
              </Flex.Item>
            )}
            {'updated_at' in item && (
              <Flex.Item>
                <Text weight="bold">{I18n.t('Date Modified')}</Text>
                <br />
                <Text>{new Date(item.updated_at).toLocaleString()}</Text>
              </Flex.Item>
            )}
          </Flex>
        </View>
      </Flex.Item>
    </Flex>
  )
}

export default FilePreviewTray
