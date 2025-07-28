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
import {Text, type TextProps} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {Flex} from '@instructure/ui-flex'
import {IconAddSolid, IconXSolid} from '@instructure/ui-icons'
import {InstUISettingsProvider} from '@instructure/emotion'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TruncateText} from '@instructure/ui-truncate-text'

const componentOverrides = {
  Tag: {
    defaultBackground: 'white',
  },
}

const I18n = createI18nScope('pill')
const ellipsis = () => I18n.t('…')
const truncate = (text: string) => (text.length > 14 ? text.slice(0, 13) + ellipsis() : text)

function renderText(
  text: string,
  truncatedText: string,
  textColor: TextProps['color'],
): JSX.Element {
  const isTruncated = text.length > truncatedText.length
  if (isTruncated) {
    return (
      <Tooltip renderTip={text}>
        <Text as="div" color={textColor}>
          <TruncateText>{truncatedText}</TruncateText>
        </Text>
      </Tooltip>
    )
  } else {
    return (
      <Text as="div" color={textColor}>
        <TruncateText>{text}</TruncateText>
      </Text>
    )
  }
}

function renderIcon(selected: boolean) {
  if (selected) {
    return <IconXSolid data-testid="item-selected" />
  } else {
    return <IconAddSolid data-testid="item-unselected" color="brand" />
  }
}

type PillPropsBase = {
  studentId: string
  text: string
  selected?: boolean
}

type PillPropsWithObserver = PillPropsBase & {
  observerId: string
  onClick: (studentId: string, observerId: string) => void
}

type PillPropsWithoutObserver = PillPropsBase & {
  observerId?: undefined
  onClick: (studentId: string) => void
}

export type PillProps = PillPropsWithoutObserver | PillPropsWithObserver

const Pill = ({studentId, observerId, text, onClick, selected = false}: PillProps) => {
  const textColor = selected ? 'primary' : 'secondary'
  const truncatedText = truncate(text)
  const testId = observerId ? 'observer-pill' : 'student-pill'

  const ariaLabel = selected ? I18n.t('Remove %{text}', {text}) : I18n.t('Add %{text}', {text})

  const contents = (
    <Flex as="div" margin="0 xxx-small 0 0" justifyItems="space-between">
      <Flex.Item
        size="0.75rem"
        shouldGrow={true}
        margin="0 xx-small 0 0"
        overflowX="hidden"
        aria-label={ariaLabel}
      >
        {renderText(text, truncatedText, textColor)}
      </Flex.Item>
      <Flex.Item padding="0 0 xxx-small 0">{renderIcon(selected)}</Flex.Item>
    </Flex>
  )

  return (
    <InstUISettingsProvider theme={{componentOverrides}}>
      <Tag
        text={contents}
        data-testid={testId}
        onClick={() => {
          if (observerId !== undefined) {
            onClick(studentId, observerId)
          } else {
            onClick(studentId)
          }
        }}
      />
    </InstUISettingsProvider>
  )
}

export default Pill
