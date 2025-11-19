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
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconMoreLine, IconPublishSolid} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'

const I18n = createI18nScope('ai_experiences_edit')

interface FormHeaderProps {
  isEdit: boolean
  onDeleteClick: () => void
}

const FormHeader: React.FC<FormHeaderProps> = ({isEdit, onDeleteClick}) => {
  return (
    <Flex justifyItems="space-between" alignItems="start" margin="0 0 large 0">
      <Flex.Item shouldGrow>
        <Heading level="h1" margin="0">
          {isEdit ? I18n.t('Edit AI Experience') : I18n.t('New AI Experience')}
        </Heading>
      </Flex.Item>
      <Flex.Item>
        <Flex alignItems="center">
          <Flex.Item padding="0 x-small 0 0">
            <IconPublishSolid color="secondary" />
          </Flex.Item>
          <Flex.Item padding="0 x-small 0 0">
            <Text color="secondary">{I18n.t('Not published')}</Text>
          </Flex.Item>
          <Flex.Item>
            <Menu
              placement="bottom end"
              trigger={
                <IconButton
                  screenReaderLabel={I18n.t('More options')}
                  withBackground={false}
                  withBorder={false}
                >
                  <IconMoreLine />
                </IconButton>
              }
            >
              <Menu.Item
                data-testid="ai-experience-edit-delete-menu-item"
                onClick={onDeleteClick}
                disabled={!isEdit}
              >
                {I18n.t('Delete')}
              </Menu.Item>
            </Menu>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

export default FormHeader
