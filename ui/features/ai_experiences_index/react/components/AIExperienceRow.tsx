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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {IconPublishSolid, IconUnpublishedLine, IconMoreLine} from '@instructure/ui-icons'

interface AIExperienceRowProps {
  id: number
  title: string
  workflowState: 'published' | 'unpublished'
  experienceType: string
  onEdit: (id: number) => void
  onTestConversation: (id: number) => void
  onPublishToggle: (id: number, newState: 'published' | 'unpublished') => void
}

const AIExperienceRow: React.FC<AIExperienceRowProps> = ({
  id,
  title,
  workflowState,
  experienceType,
  onEdit,
  onTestConversation,
  onPublishToggle,
}) => {
  const I18n = useI18nScope('ai_experiences')
  const isPublished = workflowState === 'published'

  const handlePublishToggle = () => {
    const newState = isPublished ? 'unpublished' : 'published'
    console.log(`Toggling AI experience ${id} from ${workflowState} to ${newState}`)
    onPublishToggle(id, newState)
  }

  return (
    <View
      as="div"
      background="primary"
      borderWidth="small"
      borderColor="primary"
      borderRadius="medium"
      padding="medium"
      margin="0 0 medium 0"
    >
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item>
          <Flex alignItems="center" gap="medium">
            <Flex.Item>
              <IconButton
                size="small"
                withBackground={false}
                withBorder={false}
                onClick={handlePublishToggle}
                screenReaderLabel={
                  isPublished ? I18n.t('Unpublish AI Experience') : I18n.t('Publish AI Experience')
                }
              >
                {isPublished ? (
                  <IconPublishSolid color="success" size="small" />
                ) : (
                  <IconUnpublishedLine color="secondary" size="small" />
                )}
              </IconButton>
            </Flex.Item>
            <Flex.Item>
              <View as="div">
                <Text weight="bold" size="large">
                  {title}
                </Text>
                <View as="div" margin="xx-small 0 0 0">
                  <Text size="small" color="secondary">
                    {experienceType}
                  </Text>
                </View>
              </View>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item>
          <Menu
            trigger={
              <IconButton
                size="small"
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('AI Experience Options')}
              >
                <IconMoreLine />
              </IconButton>
            }
          >
            <Menu.Item onSelect={() => onEdit(id)}>{I18n.t('Edit')}</Menu.Item>
            <Menu.Item onSelect={() => onTestConversation(id)}>
              {I18n.t('Test Conversation')}
            </Menu.Item>
          </Menu>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default AIExperienceRow
