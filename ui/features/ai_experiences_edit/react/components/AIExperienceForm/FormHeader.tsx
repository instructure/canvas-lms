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
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconPublishSolid} from '@instructure/ui-icons'
import {
  navyButtonTheme,
  lightBlueButtonTheme,
} from '../../../../../shared/ai-experiences/react/brand'

const I18n = createI18nScope('ai_experiences_edit')

interface FormHeaderProps {
  isEdit: boolean
  title?: string
  onCancel: () => void
  isLoading: boolean
}

const FormHeader: React.FC<FormHeaderProps> = ({isEdit, title, onCancel, isLoading}) => {
  const getHeading = () => {
    if (!isEdit) {
      return I18n.t('New Knowledge Chat')
    }
    if (title?.trim()) {
      return I18n.t('Edit %{title}', {title})
    }
    return I18n.t('Edit Knowledge Chat')
  }

  return (
    <Flex justifyItems="space-between" alignItems="start" margin="0 0 large 0">
      <Flex.Item shouldGrow>
        <Heading level="h1" margin="0">
          {getHeading()}
        </Heading>
      </Flex.Item>
      <Flex.Item>
        <Flex alignItems="center" gap="x-small">
          <Flex.Item>
            <IconPublishSolid color="secondary" />
          </Flex.Item>
          <Flex.Item>
            <Text color="secondary">{I18n.t('Not published')}</Text>
          </Flex.Item>
          <Flex.Item>
            <Button
              data-testid="ai-experience-edit-cancel-button"
              color="primary"
              themeOverride={lightBlueButtonTheme}
              onClick={onCancel}
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              data-testid="ai-experience-save-as-draft-item"
              type="submit"
              color="primary"
              themeOverride={navyButtonTheme}
              interaction={isLoading ? 'disabled' : 'enabled'}
            >
              {isLoading ? I18n.t('Saving...') : I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

export default FormHeader
