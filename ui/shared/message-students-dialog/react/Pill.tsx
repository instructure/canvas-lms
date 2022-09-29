/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-tooltip'
import {Flex} from '@instructure/ui-flex'
import {IconAddSolid, IconXSolid} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {useScope as useI18nScope} from '@canvas/i18n'

const themeOverride = {
  [Tag.theme]: {
    defaultBackground: 'white',
  },
}

const I18n = useI18nScope('pill')
const ellipsis = () => I18n.t('…')
const truncate = text => (text.length > 14 ? text.slice(0, 13) + ellipsis() : text)

function renderIcon(selected) {
  if (selected) {
    return <IconXSolid data-testid="item-selected" />
  } else {
    return <IconAddSolid data-testid="item-unselected" color="brand" />
  }
}

const Pill = ({studentId, observerId = null, text, onClick, selected = false}) => {
  const textColor = selected ? 'primary' : 'secondary'
  const truncatedText = truncate(text)

  const contents =
    text < truncatedText ? (
      <>
        <Flex margin="0 small 0 0" justifyItems="space-between">
          <Flex.Item>
            <Tooltip as="div" renderTip={text}>
              <Text color={textColor}>{truncatedText}</Text>
            </Tooltip>
          </Flex.Item>
          <Flex.Item>{renderIcon(selected)}</Flex.Item>
        </Flex>
      </>
    ) : (
      <>
        <View margin="0 small 0 0">
          <Text color={textColor}>{text}</Text>
        </View>
        {renderIcon(selected)}
      </>
    )

  return (
    <ApplyTheme theme={themeOverride}>
      <Tag text={contents} onClick={() => onClick(studentId, observerId)} />
    </ApplyTheme>
  )
}

export default Pill
