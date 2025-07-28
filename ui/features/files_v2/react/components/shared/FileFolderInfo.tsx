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

import React, {useCallback} from 'react'
import {type File, type Folder} from '../../../interfaces/File'
import {getIcon} from '../../../utils/fileFolderUtils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconCollectionLine} from '@instructure/ui-icons'
import friendlyBytes from '@canvas/files/util/friendlyBytes'

const I18n = createI18nScope('files_v2')

interface FileFolderInfoProps {
  items: (File | Folder)[]
}

const FileFolderInfo = ({items}: FileFolderInfoProps) => {
  const multiple = items.length > 1

  const renderIcon = useCallback(() => {
    const item = items[0]
    if (multiple) {
      return (
        <IconCollectionLine
          data-testid="multiple-items-icon"
          color="primary"
          title={I18n.t('Multiple Items')}
          size="medium"
        />
      )
    } else if (item.thumbnail_url) {
      return <Img height="3em" width="3em" alt="" src={item.thumbnail_url} />
    } else {
      return getIcon(item, !!item.folder_id, item.thumbnail_url, {size: 'medium'})
    }
  }, [items, multiple])

  const renderTitle = useCallback(() => {
    const item = items[0]
    const text = multiple
      ? I18n.t('Selected Items (%{count})', {count: items.length})
      : item.display_name || item.filename || item.name
    return (
      <Text weight="bold">
        <TruncateText position="middle">{text}</TruncateText>
      </Text>
    )
  }, [items, multiple])

  const renderSubtitle = useCallback(() => {
    if (multiple) return null

    const item = items[0]
    return <Text size="small">{item.size ? friendlyBytes(item.size) : I18n.t('Folder')}</Text>
  }, [items, multiple])

  if (items.length === 0) return null

  return (
    <View as="div" borderWidth="small" borderRadius="medium" padding="xxx-small">
      <Flex padding="x-small" gap="small">
        <Flex.Item aria-hidden={true}>{renderIcon()}</Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          {renderTitle()}
          {renderSubtitle()}
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default FileFolderInfo
