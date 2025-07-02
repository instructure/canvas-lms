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

import React, {useState, useEffect} from 'react'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {AccessibleContent} from '@instructure/ui-a11y-content'

import {useScope as createI18nScope} from '@canvas/i18n'

interface IssuesCounterProps {
  count: number
}

export const IssuesCounter: React.FC<IssuesCounterProps> = ({count}: IssuesCounterProps) => {
  const I18n = createI18nScope('accessibility_checker')
  return (
    <AccessibleContent
      alt={I18n.t(
        {
          one: '1 Total Issue',
          other: '%{count} Total Issues',
          zero: 'No Issues',
        },
        {count},
      )}
    >
      <Flex
        direction="column"
        height="100%"
        alignItems="center"
        justifyItems="center"
        textAlign="center"
      >
        <Flex.Item>
          <Heading
            data-testid="counter-number"
            themeOverride={(_componentTheme, currentTheme) => ({
              primaryColor:
                count > 0
                  ? currentTheme.colors.primitives.orange57
                  : currentTheme.colors.primitives.green57,
            })}
            color="primary"
            variant="titleSection"
          >
            {count}
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <Text data-testid="counter-description" variant="descriptionSection">
            {I18n.t(
              {
                one: 'Total Issue',
                other: 'Total Issues',
                zero: 'Total Issues',
              },
              {count},
            )}
          </Text>
        </Flex.Item>
      </Flex>
    </AccessibleContent>
  )
}
