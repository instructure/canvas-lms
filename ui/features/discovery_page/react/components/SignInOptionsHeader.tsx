/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconAddLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {SignInOptionsHeaderProps} from '../types'

const I18n = createI18nScope('discovery_page')

export function SignInOptionsHeader({
  title,
  description,
  onAddClick,
  disabled,
}: SignInOptionsHeaderProps) {
  return (
    <Flex as="div" direction="column" gap="xx-small">
      <Flex as="div" justifyItems="space-between" alignItems="center">
        <Heading level="h4" margin="0">
          {title}
        </Heading>

        <Button
          size="small"
          renderIcon={<IconAddLine />}
          onClick={onAddClick}
          interaction={disabled ? 'disabled' : 'enabled'}
          data-testid="add-sign-in-option-button"
        >
          {I18n.t('Add')}
        </Button>
      </Flex>

      {description && (
        <Text size="small" color="secondary">
          {description}
        </Text>
      )}
    </Flex>
  )
}
