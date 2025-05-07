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

import type {File} from '../../../../interfaces/File'
import {getRestrictedText, isHidden, isPublished, isRestricted} from '../../../../utils/fileUtils'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import friendlyBytes from '@canvas/files/util/friendlyBytes'

const I18n = createI18nScope('files_v2')

const CommonFileInfo = ({item}: {item: File}) => {
  const name = item.display_name
  const published = isPublished(item)
  const restricted = isRestricted(item)
  const hidden = isHidden(item)

  const statusText = () => {
    if (published && restricted) return getRestrictedText(item)
    if (published && hidden) return I18n.t('Hidden')
    return published ? I18n.t('Published') : I18n.t('Unpublished')
  }

  return (
    <Flex direction="column" gap="small">
      <Heading margin="0 0 large">{I18n.t('File Info')}</Heading>
      <Flex.Item>
        <Text weight="bold">{I18n.t('Name')}</Text>
        <br />
        <View as="div" display="inline-block" width="250px">
          <Tooltip renderTip={name}>
            <Text data-testid="file-display-name">
              <TruncateText>{name}</TruncateText>
            </Text>
          </Tooltip>
        </View>
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
          <Text>{friendlyBytes(item.size)}</Text>
        </Flex.Item>
      )}
      {'created_at' in item && (
        <Flex.Item>
          <Text weight="bold">{I18n.t('Date Created')}</Text>
          <br />
          <Text>
            {new Date(item.created_at).toLocaleString(ENV.LOCALE, {
              timeZone: ENV.TIMEZONE,
            })}
          </Text>
        </Flex.Item>
      )}
      {'updated_at' in item && (
        <Flex.Item>
          <Text weight="bold">{I18n.t('Date Modified')}</Text>
          <br />
          <Text>
            {new Date(item.updated_at).toLocaleString(ENV.LOCALE, {
              timeZone: ENV.TIMEZONE,
            })}
          </Text>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default CommonFileInfo
