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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {iconMap} from '../../../../assets/icons'

type IconPickerProps = {
  iconName?: string
  onSelect: (iconName: string) => void
}
const IconPicker = ({iconName, onSelect}: IconPickerProps) => {
  const handleSelectIcon = useCallback(
    (newIconName: string) => {
      onSelect(newIconName)
    },
    [onSelect]
  )

  const handleKey = useCallback(
    (event: React.KeyboardEvent, newIconName: string) => {
      if (event.key === 'Enter') {
        handleSelectIcon(newIconName)
      }
    },
    [handleSelectIcon]
  )

  const selectedStyle = {borderColor: 'var(--ic-brand-primary)'}
  const iconButtonStyle = {
    padding: '2px',
    display: 'inline-block',
    cursor: 'pointer',
    borderWidth: '1px',
    borderStyle: 'solid',
    borderColor: 'transparent',
    borderRadius: '4px',
  }

  const renderNoIcon = () => {
    const isSelected = !iconName
    let style = {...iconButtonStyle}
    if (isSelected) style = {...style, ...selectedStyle}

    return (
      <div
        role="button"
        style={style}
        tabIndex={0}
        onClick={() => handleSelectIcon('')}
        onKeyDown={(event: React.KeyboardEvent) => handleKey(event, '')}
      >
        <Text size="small">No Icon</Text>
      </div>
    )
  }

  return (
    <View as="div" margin="small" borderWidth="small" maxWidth="17rem">
      <Flex wrap="wrap" gap="small" justifyItems="space-between" margin="x-small">
        {Object.keys(iconMap).map(icon => {
          const Icon = iconMap[icon]
          const isSelected = icon === iconName
          let style = {...iconButtonStyle}
          if (isSelected) {
            style = {...style, ...selectedStyle}
          }
          return (
            <div
              key={icon}
              role="button"
              style={style}
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
