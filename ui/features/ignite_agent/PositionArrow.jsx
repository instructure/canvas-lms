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

import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('IgniteAgent')

import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowDoubleStartLine, IconArrowDoubleEndLine} from '@instructure/ui-icons'
import React, {useCallback} from 'react'
import {useAgentContainer} from './AgentContainerContext'
import {MIN_POSITION, KEYBOARD_STEP} from './constants'

export function PositionArrow({direction}) {
  const {buttonPosition, setButtonPosition, getMaxPosition, constrainPosition, viewportHeight} =
    useAgentContainer()

  const movePosition = useCallback(() => {
    const delta = direction === 'up' ? KEYBOARD_STEP : -KEYBOARD_STEP
    setButtonPosition(pos => constrainPosition(pos + delta, viewportHeight))
  }, [direction, setButtonPosition, constrainPosition, viewportHeight])

  const handleKeyDown = useCallback(
    e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        movePosition()
      }
    },
    [movePosition],
  )

  const isDisabled =
    direction === 'up'
      ? buttonPosition >= getMaxPosition(viewportHeight)
      : buttonPosition <= MIN_POSITION

  const Icon = direction === 'up' ? IconArrowDoubleStartLine : IconArrowDoubleEndLine
  const label = I18n.t('Move button %{direction} (currently at %{position}% from bottom)', {
    direction,
    position: Math.round(buttonPosition),
  })

  return (
    <View display="block">
      <IconButton
        onClick={movePosition}
        onKeyDown={handleKeyDown}
        screenReaderLabel={label}
        renderIcon={() => <Icon rotate="90" />}
        size="small"
        withBackground={false}
        withBorder={false}
        disabled={isDisabled}
      />
    </View>
  )
}
