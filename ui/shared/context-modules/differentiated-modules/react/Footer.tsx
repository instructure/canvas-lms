/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface FooterProps {
  saveButtonLabel: string
  disableSave?: boolean
  onDismiss: () => void
  onUpdate: () => void
  hasErrors?: boolean
}

export default function Footer({
  saveButtonLabel,
  disableSave = false,
  onDismiss,
  onUpdate,
  hasErrors = false,
}: FooterProps) {
  const updateButton = () => {
    if (hasErrors) {
      return (
        <Tooltip
          renderTip={I18n.t('Please fix errors before continuing')}
          on={['click', 'focus', 'hover']}
        >
          <Button
            color="primary"
            onClick={onUpdate}
            data-testid="differentiated_modules_save_button"
          >
            {saveButtonLabel}
          </Button>
        </Tooltip>
      )
    } else {
      return (
        <Button
          interaction={disableSave ? 'disabled' : 'enabled'}
          color="primary"
          onClick={onUpdate}
          data-testid="differentiated_modules_save_button"
        >
          {saveButtonLabel}
        </Button>
      )
    }
  }

  return (
    <View as="div" padding="small" background="secondary" borderWidth="small none none none">
      <Flex as="div" justifyItems="end">
        <Flex.Item>
          <Button data-testid="differentiated_modules_cancel_button" onClick={onDismiss}>
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">{updateButton()}</Flex.Item>
      </Flex>
    </View>
  )
}
