/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {type File, type Folder} from '../../../interfaces/File'
import {getIcon} from '../../../utils/fileFolderUtils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {formatFileSize} from '@canvas/util/fileHelper'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconCollectionLine} from '@instructure/ui-icons'

const I18n = createI18nScope('files_v2')

interface FileFolderInfoProps {
  items: (File | Folder)[]
}

const FileFolderInfo = ({items}: FileFolderInfoProps) => {
  if (items.length === 0) return null

  if (items.length > 1) {
    return (
      <View as="div" borderWidth="small" borderRadius="medium" padding="xxx-small" key="multiple-items">
        <Flex padding="x-small" gap="small">
          <Flex.Item>
            <IconCollectionLine
                data-testid="multiple-items-icon"
                color="primary"
                title={I18n.t('Multiple Items')}
                size="medium"
            />
          </Flex.Item>

          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Text weight="bold">
              <TruncateText position="middle">
                {I18n.t('Selected Items (%{count})', {count: items.length})}
              </TruncateText>
            </Text>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  const item = items[0]

  return (
    <View as="div" borderWidth="small" borderRadius="medium" padding="xxx-small" key={item.id}>
      <Flex padding="x-small" gap="small">
        <Flex.Item>
          {item.thumbnail_url ? (
            <Img height="3em" width="3em" alt="" src={item.thumbnail_url} />
          ) : (
            getIcon(item, !!item.folder_id, item.thumbnail_url, {size: 'medium'})
          )}
        </Flex.Item>

        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text weight="bold">
            <TruncateText position="middle">
              {item.display_name || item.filename || item.name}
            </TruncateText>
          </Text>
          <Text size="small">{item.size ? formatFileSize(item.size) : I18n.t('Folder')}</Text>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default FileFolderInfo
