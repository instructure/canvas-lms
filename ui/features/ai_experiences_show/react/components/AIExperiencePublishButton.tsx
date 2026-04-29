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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconCompleteLine, IconMinimizeLine} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@instructure/platform-alerts'
import {publishedButtonTheme, buttonTheme} from '../../../../shared/ai-experiences/react/brand'

const I18n = createI18nScope('ai_experiences_show')

interface AIExperiencePublishButtonProps {
  experienceId: string
  courseId: string | number
  isPublished: boolean
  canUnpublish: boolean
  contextReady: boolean
  indexFailed?: boolean
  onPublishChange: (newState: 'published' | 'unpublished') => void
}

const AIExperiencePublishButton: React.FC<AIExperiencePublishButtonProps> = ({
  experienceId,
  courseId,
  isPublished,
  canUnpublish,
  contextReady,
  indexFailed,
  onPublishChange,
}) => {
  const [isUpdating, setIsUpdating] = useState(false)

  const isDisabled = isUpdating || (isPublished && !canUnpublish) || (!isPublished && !contextReady)

  const getDisabledReason = () => {
    if (isUpdating) return I18n.t('Updating...')
    if (isPublished && !canUnpublish) {
      return I18n.t(
        'Cannot change state: students have conversations or source files are still processing',
      )
    }
    if (!isPublished && !contextReady) {
      return indexFailed
        ? I18n.t('Cannot publish: remove the failed source file and save again')
        : I18n.t('Cannot publish: source files are still processing')
    }
    return ''
  }

  const handlePublish = async (newState: 'published' | 'unpublished') => {
    setIsUpdating(true)
    try {
      await doFetchApi({
        path: `/api/v1/courses/${courseId}/ai_experiences/${experienceId}`,
        method: 'PUT',
        body: {
          ai_experience: {
            workflow_state: newState,
          },
        },
      })

      const message =
        newState === 'published'
          ? I18n.t('Knowledge Chat published successfully')
          : I18n.t('Knowledge Chat unpublished successfully')

      showFlashSuccess(message)()
      onPublishChange(newState)
    } catch (error: any) {
      const message =
        error?.response?.data?.errors?.workflow_state?.[0] ||
        I18n.t('Failed to update Knowledge Chat')
      showFlashError(message)()
    } finally {
      setIsUpdating(false)
    }
  }

  const button = (
    <Button
      renderIcon={isPublished ? <IconCompleteLine /> : <IconMinimizeLine />}
      color={isPublished ? 'primary' : 'secondary'}
      themeOverride={isPublished ? publishedButtonTheme : buttonTheme}
      interaction={isDisabled ? 'disabled' : 'enabled'}
      onClick={() => handlePublish(isPublished ? 'unpublished' : 'published')}
      data-testid="ai-experience-publish-button"
    >
      {isPublished ? I18n.t('Published') : I18n.t('Unpublished')}
    </Button>
  )

  return isDisabled && !isUpdating ? (
    <Tooltip renderTip={getDisabledReason()} on={['hover', 'focus']}>
      {button}
    </Tooltip>
  ) : (
    button
  )
}

export default AIExperiencePublishButton
