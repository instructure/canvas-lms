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

import React, {useCallback, useState} from 'react'
import classNames from 'classnames'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {getArrowNext, getArrowPrev} from '../../../../utils'

import {iconMap} from '../../../../assets/user-icons'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type IconPickerProps = {
  iconName?: string
  onSelect: (iconName: string) => void
  onClose: () => void
}
const IconPicker = ({iconName, onSelect, onClose}: IconPickerProps) => {
  const [arrowNext] = useState(getArrowNext())
  const [arrowPrev] = useState(getArrowPrev())
  const handleSelectIcon = useCallback(
    (newIconName: string) => {
      onSelect(newIconName)
    },
    [onSelect],
  )

  const handleKey = useCallback(
    (event: React.KeyboardEvent, newIconName: string) => {
      if (
        ['Enter', 'Escape', 'ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].includes(event.key)
      ) {
        event.stopPropagation()
        event.preventDefault()
      }
      if (event.key === 'Enter') {
        handleSelectIcon(newIconName)
      } else if (event.key === 'Escape') {
        onClose()
      } else if (arrowNext.includes(event.key)) {
        ;(event.currentTarget.nextElementSibling as HTMLElement)?.focus()
      } else if (arrowPrev.includes(event.key)) {
        ;(event.currentTarget.previousElementSibling as HTMLElement)?.focus()
      }
    },
    [arrowNext, arrowPrev, handleSelectIcon, onClose],
  )

  const renderNoIcon = () => {
    const isSelected = !iconName

    return (
      <div
        className={classNames('icon-picker__icon', {
          selected: isSelected,
        })}
        role="button"
        tabIndex={0}
        onClick={() => handleSelectIcon('')}
        onKeyDown={(event: React.KeyboardEvent) => handleKey(event, '')}
      >
        <Text size="small">{I18n.t('No Icon')}</Text>
      </div>
    )
  }

  return (
    <View as="div" margin="small" borderWidth="small" maxWidth="17rem">
      <Flex wrap="wrap" gap="small" justifyItems="space-between" margin="x-small">
        <ScreenReaderContent>{I18n.t('Select an icon')}</ScreenReaderContent>
        {Object.keys(iconMap).map(icon => {
          const Icon = iconMap[icon]
          const isSelected = icon === iconName
          return (
            <div
              className={classNames('icon-picker__icon', {
                selected: isSelected,
              })}
              key={icon}
              role="button"
              tabIndex={0}
              onClick={() => handleSelectIcon(icon)}
              onKeyDown={(event: React.KeyboardEvent) => handleKey(event, icon)}
            >
              <Icon size="small" />
            </div>
          )
        })}
        {renderNoIcon()}
      </Flex>
    </View>
  )
}

export {IconPicker}
