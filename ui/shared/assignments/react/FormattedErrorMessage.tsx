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
import {Flex} from '@instructure/ui-flex'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import type {Spacing} from '@instructure/emotion'

export type FormattedErrorMessageProps = {
  message: string,
  margin?: Spacing,
  iconMargin?: Spacing,
}

const FormattedErrorMessage = ({message, margin, iconMargin}: FormattedErrorMessageProps) => {
  return (
    <Flex as='div' alignItems='center' margin={margin || '0'} data-testid='error-message-container'>
      <Flex as='div' alignItems='center' margin={iconMargin || '0 xx-small 0 0'}>
        <IconWarningSolid color='error' data-testid='warning-icon' />
      </Flex>
      <Text size='small' color='danger'>
        {message}
      </Text>
    </Flex>
  )
}

export default FormattedErrorMessage
