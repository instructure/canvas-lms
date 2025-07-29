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

import React, {useState} from 'react'
import {type ViewProps} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ToggleButton} from '@instructure/ui-buttons'
import {IconBlueprintLockSolid, IconBlueprintSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useContextModule} from '../hooks/useModuleContext'
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('context_modules_v2')

interface BlueprintLockIconProps {
  initialLockState: boolean
  contentId?: string
  contentType: string
}

export const LOCK_ICON_CLASS = {locked: 'lock-icon-locked', unlocked: 'lock-icon-unlock'}

const mapContentType = (contentType: string) => {
  const content_type = contentType.toLowerCase()
  switch (content_type) {
    case 'discussion':
      return 'discussion_topic'
    case 'page':
      return 'wiki_page'
    case 'file':
      return 'attachment'
    default:
      return content_type
  }
}

const BlueprintLockIcon: React.FC<BlueprintLockIconProps> = props => {
  const {initialLockState, contentId, contentType} = props

  const {courseId, isChildCourse} = useContextModule()

  const [isLocked, setIsLocked] = useState(initialLockState)

  const handleClick = (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
    event.preventDefault()
    event.stopPropagation()

    if (isLocked) {
      setLockState(false)
    } else {
      setLockState(true)
    }
  }

  const setLockState = (locked: boolean) => {
    if (!courseId || !contentId || !contentType) return

    const formData = new FormData()
    formData.append('content_type', mapContentType(contentType))
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
          showFlashError(
            I18n.t('An error occurred %{op} item', {
              op: locked ? I18n.t('locking') : I18n.t('unlocking'),
            }),
          )()
        }
      })
      .catch((error: Error) => {
        showFlashError(
          I18n.t('An error occurred %{op} item', {
            op: locked ? I18n.t('locking') : I18n.t('unlocking'),
          }),
        )()
      })
  }

  const getIcon = () => {
    return isLocked ? <IconBlueprintLockSolid /> : <IconBlueprintSolid />
  }

  const renderChildCourseIcon = () => {
    return getIcon()
  }

  const renderParentCourseIcon = () => {
    const text = isLocked ? I18n.t('Locked. Click to unlock.') : I18n.t('Unlocked. Click to lock.')

    return (
      <ToggleButton
        data-testid="blueprint-lock-button"
        size="small"
        onClick={handleClick}
        status={isLocked ? 'pressed' : 'unpressed'}
        screenReaderLabel={text}
        renderTooltipContent={text}
        renderIcon={getIcon}
      />
    )
  }

  return isChildCourse ? renderChildCourseIcon() : renderParentCourseIcon()
}

export default BlueprintLockIcon
