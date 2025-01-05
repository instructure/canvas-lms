/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconWarningSolid} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('content_migrations_redesign')

type FormMessageProps = {
  children?: React.ReactNode
}

export const ErrorFormMessage = ({children}: FormMessageProps) => {
  return (
    <Text color="danger" size="small">
      <Flex gap="xx-small" alignItems="center">
        <IconWarningSolid color="error" />
        {children}
      </Flex>
    </Text>
  )
}

export const noFileSelectedFormMessage: FormMessage = {
  text: I18n.t('You must select a file to import content from'),
  type: 'newError',
}
