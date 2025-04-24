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

import React, {useState, KeyboardEvent, MouseEvent} from 'react'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconBlueprintLockSolid, IconBlueprintSolid} from '@instructure/ui-icons'
import {useContextModule} from '../hooks/useModuleContext'
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('context_modules_v2')

interface BlueprintLockIconProps {
  initialLockState: boolean
  contentId?: string
  contentType: string
}

export const LOCK_ICON_CLASS = {locked: 'lock-icon-locked', unlocked: 'lock-icon-unlock'}

const BlueprintLockIcon: React.FC<BlueprintLockIconProps> = props => {
  const {initialLockState, contentId, contentType} = props

  const {courseId, isChildCourse} = useContextModule()
  const lockText = I18n.t('Locked. Click to unlock.')
  const unlockText = I18n.t('Unlocked. Click to lock.')

  const [isLocked, setIsLocked] = useState(initialLockState)
  const [isHovering, setIsHovering] = useState(false)

  const handleClick = (event: MouseEvent | KeyboardEvent) => {
    event.preventDefault()
    event.stopPropagation()

    if (isChildCourse) return

    if (isLocked) {
      setLockState(false)
    } else {
      setLockState(true)
    }
  }

  const handleKeyClick = (event: KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      handleClick(event)
    }
  }

  const setLockState = (locked: boolean) => {
    if (!courseId || !contentId || !contentType) return

    const formData = new FormData()
    formData.append('content_type', contentType)
    formData.append('content_id', contentId)
    formData.append('restricted', locked.toString())
    formData.append('_method', 'PUT')

    doFetchApi({
      path: `/api/v1/courses/${courseId}/blueprint_templates/default/restrict_item`,
      method: 'POST',
      body: formData,
    })
      .then((response: DoFetchApiResults<unknown>) => {
        if (response.response.ok) {
          setIsLocked(locked)
        } else {
          console.error('Error setting lock state:', response)
        }
      })
      .catch((error: Error) => {
        console.error('Error setting lock state:', error)
      })
  }

  const handleMouseEnter = () => {
    if (!isChildCourse) {
      setIsHovering(true)
    }
  }

  const handleMouseLeave = () => {
    if (!isChildCourse) {
      setIsHovering(false)
    }
  }

  const getTooltipText = () => {
    if (isChildCourse) {
      return isLocked ? I18n.t('Locked') : I18n.t('Unlocked')
    }

    if (isHovering) {
      return isLocked ? I18n.t('Click to unlock') : I18n.t('Click to lock')
    } else {
      return isLocked ? lockText : unlockText
    }
  }

  const getIcon = () => {
    if (isLocked) {
      return <IconBlueprintLockSolid />
    } else {
      return <IconBlueprintSolid />
    }
  }

  const tooltipText = getTooltipText()
  const iconClass = isLocked ? LOCK_ICON_CLASS.locked : LOCK_ICON_CLASS.unlocked
  const disabledClass = isChildCourse ? 'disabled' : ''

  return (
    <View
      as="span"
      className={`lock-icon ${iconClass} ${disabledClass}`}
      data-testid={iconClass}
      onClick={handleClick}
      onKeyDown={handleKeyClick}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      tabIndex={isChildCourse ? -1 : 0}
      role="button"
      aria-pressed={isLocked}
      disabled={isChildCourse}
    >
      <Tooltip
        renderTip={tooltipText}
        data-testid={`lock-icon-tooltip-${iconClass}`}
        placement="top"
        color="primary"
        on={['hover', 'focus']}
      >
        {getIcon()}
        <ScreenReaderContent>{isLocked ? lockText : unlockText}</ScreenReaderContent>
      </Tooltip>
    </View>
  )
}

export default BlueprintLockIcon
