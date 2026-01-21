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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {
  IconArrowOpenDownSolid,
  IconArrowOpenUpSolid,
  IconNoLine,
  IconPublishSolid,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('ai_experiences_show')

interface AIExperiencePublishButtonProps {
  experienceId: string
  courseId: string | number
  isPublished: boolean
  canUnpublish: boolean
  onPublishChange: (newState: 'published' | 'unpublished') => void
}

const AIExperiencePublishButton: React.FC<AIExperiencePublishButtonProps> = ({
  experienceId,
  courseId,
  isPublished,
  canUnpublish,
  onPublishChange,
}) => {
  const [menuOpen, setMenuOpen] = useState(false)
  const [isUpdating, setIsUpdating] = useState(false)

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
          ? I18n.t('AI Experience published successfully')
          : I18n.t('AI Experience unpublished successfully')

      showFlashSuccess(message)()
      onPublishChange(newState)
    } catch (error: any) {
      const message =
        error?.response?.data?.errors?.workflow_state?.[0] ||
        I18n.t('Failed to update AI Experience')
      showFlashError(message)()
    } finally {
      setIsUpdating(false)
    }
  }

  return (
    <Menu
      placement="bottom end"
      onToggle={show => setMenuOpen(show)}
      trigger={
        <Button
          renderIcon={isPublished ? <IconPublishSolid /> : <IconNoLine />}
          color="primary-inverse"
          themeOverride={
            isPublished
              ? {
                  borderStyle: 'none',
                  primaryInverseColor: '#03893D',
                }
              : {borderStyle: 'none'}
          }
          interaction={isUpdating ? 'disabled' : 'enabled'}
          data-testid="ai-experience-publish-button"
        >
          <Flex alignItems="center" gap="x-small">
            <Flex.Item>{isPublished ? I18n.t('Published') : I18n.t('Unpublished')}</Flex.Item>
            <Flex.Item>
              {menuOpen ? (
                <IconArrowOpenUpSolid size="x-small" />
              ) : (
                <IconArrowOpenDownSolid size="x-small" />
              )}
            </Flex.Item>
          </Flex>
        </Button>
      }
    >
      <Menu.Group label={I18n.t('State')} />
      <Menu.Item
        disabled={isPublished}
        onClick={() => handlePublish('published')}
        data-testid="publish-option"
        themeOverride={{
          labelColor: '#03893D',
        }}
      >
        <Flex>
          <Flex.Item margin="0 x-small 0 0">
            <IconPublishSolid />
          </Flex.Item>
          <Flex.Item>{I18n.t('Publish')}</Flex.Item>
        </Flex>
      </Menu.Item>
      <Menu.Item
        disabled={!isPublished || !canUnpublish}
        onClick={() => handlePublish('unpublished')}
        data-testid="unpublish-option"
      >
        <Flex direction="column" gap="xx-small">
          <Flex>
            <Flex.Item margin="0 x-small 0 0">
              <IconNoLine />
            </Flex.Item>
            <Flex.Item>{I18n.t('Unpublish')}</Flex.Item>
          </Flex>
          {!canUnpublish && isPublished && (
            <Flex.Item>
              <Text size="x-small" color="secondary">
                {I18n.t('(Students have conversations)')}
              </Text>
            </Flex.Item>
          )}
        </Flex>
      </Menu.Item>
    </Menu>
  )
}

export default AIExperiencePublishButton
