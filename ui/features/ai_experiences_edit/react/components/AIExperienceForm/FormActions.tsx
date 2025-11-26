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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Pill} from '@instructure/ui-pill'

const I18n = createI18nScope('ai_experiences_edit')

interface FormActionsProps {
  isLoading: boolean
  onCancel: () => void
  onPreview: () => void
}

const FormActions: React.FC<FormActionsProps> = ({isLoading, onCancel, onPreview}) => {
  return (
    <Flex justifyItems="end" margin="large 0 0 0">
      <Flex.Item padding="0 x-small 0 0">
        <Button data-testid="ai-experience-edit-cancel-button" onClick={onCancel}>
          {I18n.t('Cancel')}
        </Button>
      </Flex.Item>
      <Flex.Item padding="0 x-small 0 0">
        <Menu
          placement="top"
          trigger={
            <Button>
              <Flex alignItems="center">
                <Flex.Item shouldGrow>{I18n.t('Preview')}</Flex.Item>
                <Flex.Item padding="0 0 0 x-small">
                  <IconArrowOpenDownLine />
                </Flex.Item>
              </Flex>
            </Button>
          }
        >
          <Menu.Item data-testid="ai-experience-edit-preview-item" onClick={onPreview}>
            {I18n.t('Preview experience')}
          </Menu.Item>
          <Menu.Item disabled>
            <Flex justifyItems="space-between" alignItems="center" width="100%">
              <Flex.Item shouldGrow shouldShrink>
                <Text>{I18n.t('Run chat simulation')}</Text>
              </Flex.Item>
              <Flex.Item>
                <Pill color="info">{I18n.t('Coming soon')}</Pill>
              </Flex.Item>
            </Flex>
          </Menu.Item>
        </Menu>
      </Flex.Item>
      <Flex.Item>
        <Button
          data-testid="ai-experience-save-as-draft-item"
          type="submit"
          color="primary"
          interaction={isLoading ? 'disabled' : 'enabled'}
        >
          {isLoading ? I18n.t('Saving...') : I18n.t('Save as draft')}
        </Button>
      </Flex.Item>
    </Flex>
  )
}

export default FormActions
