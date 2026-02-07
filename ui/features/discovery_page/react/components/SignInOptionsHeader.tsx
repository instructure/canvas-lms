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
import {IconAddLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discovery_page')

interface SignInOptionsHeaderProps {
  title: string
  onAddClick: () => void
}

export function SignInOptionsHeader({title, onAddClick}: SignInOptionsHeaderProps) {
  return (
    <Flex as="div" justifyItems="space-between" alignItems="center">
      <Heading level="h4" margin="0">
        {title}
      </Heading>

      <Button size="small" renderIcon={<IconAddLine />} onClick={onAddClick}>
        {I18n.t('Add')}
      </Button>
    </Flex>
  )
}
