/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconAttachMediaLine, IconXLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('conversations_2')

export const MediaAttachment = props => {
  return (
    <Flex justifyItems="space-between">
      <Flex.Item>
        <View padding="0 small 0 0">
          <IconAttachMediaLine />
        </View>
        <Text size="small">{props.mediaTitle}</Text>
      </Flex.Item>
      <Flex.Item>
        <IconButton
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Remove Media Attachment')}
          onClick={props.onRemoveMedia}
          size="small"
          data-testid="remove-media-attachment"
        >
          <IconXLine />
        </IconButton>
      </Flex.Item>
    </Flex>
  )
}

MediaAttachment.propTypes = {
  mediaTitle: PropTypes.string,
  onRemoveMedia: PropTypes.func,
}
