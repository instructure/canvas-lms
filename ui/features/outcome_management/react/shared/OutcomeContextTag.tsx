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

import React, {memo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tag} from '@instructure/ui-tag'
import {IconCoursesLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {colors} from '@instructure/canvas-theme'
import IconInstitution from './IconInstitution'

const I18n = createI18nScope('OutcomeManagement')

interface OutcomeContextTagProps {
  outcomeContextType?: string
  outcomeContextId?: string
}

const OutcomeContextTag = ({outcomeContextType, outcomeContextId}: OutcomeContextTagProps) => {
  if (!outcomeContextType || !outcomeContextId) {
    return null
  }

  const isAccount = outcomeContextType === 'Account'
  const contextLabel = isAccount ? I18n.t('Institution') : I18n.t('Course')

  const ariaLabel = isAccount
    ? I18n.t('This is an institution-level outcome')
    : I18n.t('This is a course-level outcome')
  const icon = isAccount ? (
    <IconInstitution
      size="x-small"
      color="white"
      style={{transform: 'scale(0.6)', marginLeft: '-2px', marginRight: '-1px'}}
    />
  ) : (
    <IconCoursesLine
      size="x-small"
      color="primary-inverse"
      style={{
        transform: 'scale(0.55)',
        marginTop: '-2px',
        marginBottom: '-2px',
        marginLeft: '-3px',
        marginRight: '-2px',
      }}
    />
  )
  const backgroundColor = isAccount
    ? colors.primitives.violet90
    : colors.additionalPrimitives.copper45

  return (
    <Tag
      size="small"
      text={
        <Flex gap="xxx-small" padding="xxx-small 0">
          {icon}
          <Text color="primary-inverse" size="x-small" weight="normal" lineHeight="condensed">
            {contextLabel}
          </Text>
        </Flex>
      }
      themeOverride={{
        defaultBackground: backgroundColor,
        defaultBorderStyle: 'none',
      }}
      aria-label={ariaLabel}
      data-testid="outcome-context-tag"
    />
  )
}

export default memo(OutcomeContextTag)
